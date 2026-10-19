#!/usr/bin/env bash
# One-shot migration of the legacy nixpkgs OpenCode database
# (opencode-stable.db, used by channel "stable") to the canonical
# opencode.db used by upstream OpenCode 2.x.
#
# Run from a plain terminal, NOT from inside OpenCode.
# Background: https://github.com/NixOS/nixpkgs/pull/558549
set -euo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
LEGACY="$DATA/opencode-stable.db"
CANONICAL="$DATA/opencode.db"
BACKUP_DIR="$HOME/opencode-db-backup-$(date +%Y%m%d-%H%M%S)"

say() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# The nixpkgs build wraps the binary, so process names show up as
# "opencode", ".opencode-wrapp" (comm is truncated to 15 chars), or
# "opencode2".
is_opencode_comm() {
  case "$1" in
    opencode | opencode2 | .opencode-wrapp | .opencode-wrapper) return 0 ;;
    *) return 1 ;;
  esac
}

opencode_pids() {
  ps -eo pid=,comm= | while read -r p c; do
    is_opencode_comm "$c" && printf '%s\n' "$p"
  done
}

# Refuse to run under OpenCode: stopping it would take down the caller.
pid=$PPID
for _ in $(seq 1 25); do
  [[ $pid -le 1 ]] && break
  comm=$(ps -o comm= -p "$pid" 2>/dev/null || true)
  is_opencode_comm "$comm" && die "run this from a plain terminal, not inside OpenCode"
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done

command -v python3 >/dev/null || die "python3 is required"

if [[ -e $CANONICAL ]]; then
  say "canonical database already exists: $CANONICAL"
  say "nothing to migrate"
  exit 0
fi
[[ -e $LEGACY ]] || die "no OpenCode database found in $DATA"

# The database must be quiescent before renaming.
pids=$(opencode_pids)
if [[ -n $pids ]]; then
  say "stopping OpenCode processes: $(tr '\n' ' ' <<<"$pids")"
  # shellcheck disable=SC2086
  kill $pids 2>/dev/null || true
  for _ in $(seq 1 50); do
    [[ -z $(opencode_pids) ]] && break
    sleep 0.2
  done
  if [[ -n $(opencode_pids) ]]; then
    say "still running; sending SIGKILL"
    # shellcheck disable=SC2086
    kill -9 $pids 2>/dev/null || true
    sleep 1
  fi
fi
remaining=$(opencode_pids | tr '\n' ' ')
[[ -z $remaining ]] || die "OpenCode is still running: $remaining"

# Fresh consistent snapshot (safe with a WAL) right before the rename.
say "backing up to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
python3 - "$LEGACY" "$BACKUP_DIR/opencode-stable.db" <<'PY'
import sqlite3, sys
src, dst = sys.argv[1], sys.argv[2]
s = sqlite3.connect(f"file:{src}?mode=ro", uri=True)
d = sqlite3.connect(dst)
with d:
    s.backup(d)
s.close(); d.close()
PY
python3 - "$BACKUP_DIR/opencode-stable.db" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
print("    backup integrity:", c.execute("PRAGMA integrity_check").fetchone()[0])
print("    sessions:", c.execute("SELECT count(*) FROM session").fetchone()[0])
c.close()
PY

say "renaming $(basename "$LEGACY") -> $(basename "$CANONICAL")"
mv -- "$LEGACY" "$CANONICAL"
for suffix in -wal -shm; do
  [[ -e "$LEGACY$suffix" ]] && mv -- "$LEGACY$suffix" "$CANONICAL$suffix"
done

python3 - "$CANONICAL" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
print("    migrated integrity:", c.execute("PRAGMA integrity_check").fetchone()[0])
print("    sessions:", c.execute("SELECT count(*) FROM session").fetchone()[0])
c.close()
PY

say "done — OpenCode 2.x will migrate the schema on first start"
say "next: cd ~/Projects/dotfiles && sudo nixos-rebuild switch --flake .#dotfiles"
