# Launchers, menus, and shell-script conventions

How the launcher and Bluetooth menus are (and should be) written, based on the
patterns in [Omarchy](https://github.com/basecamp/omarchy) and
[DankLinux / DMS](https://github.com/AvengeMedia/DankMaterialShell).

## Why this document exists

`bin/bt-menu.sh` used to hang onto the screen: the top-level menu was wrapped in
`while :; do main_menu; done`, and dismissing the menu (Escape) returned from
`main_menu` straight back into the loop — there was **no exit path at all**, so
the menu reopened no matter what the user did. This document records the
structure that fixes that bug going forward.

## How Omarchy writes shell scripts

Omarchy puts every user-facing command in `bin/` as a **single-purpose,
well-named executable** (`omarchy-<group>-<action>`), e.g.:

- `bin/omarchy-bluetooth-power` — one job: turn BT on/off, `exit` code answers.
- `bin/omarchy-bluetooth-device` — one job: `pair|connect|disconnect|forget <mac>`.

Conventions we borrowed:

| Omarchy convention | What it means |
|---|---|
| Single-purpose commands | A script does one thing and answers with exit codes, not side-effecting UI. Menus are thin and delegate. |
| Strict mode | `set -euo pipefail`; shebang `#!/bin/bash`. |
| Metadata comments | `# omarchy:summary=…`, `# omarchy:args=[…]`, `# omarchy:group=…` so `omarchy` can auto-document the CLI. |
| Hard input validation | e.g. address must match `^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$` before doing anything. |
| rfkill-aware Bluetooth power | Background: BlueZ never persists `Powered`, but the rfkill soft block does (systemd-rfkill restores it at boot). So *block/unblock is the state*, and `bluetoothctl power on` fails outright while the block is set. |
| Check *all* controllers | `bluetoothctl list \| awk '{print $2}'` then probe each — a bare `bluetoothctl show` only reports the default controller and can miss a powered dongle. |
| Deadline wait, not sleep probes | One deadline (`((SECONDS < deadline))`) around a poll loop instead of `sleep N` + fixed retry count, so a wedged D-Bus can't stretch a 2s wait into 30s. |
| Helper commands | `omarchy-notification-send`, `omarchy-cmd-present`, `omarchy-pkg-add` … — never raw `notify-send`/`command -v`/`pacman` in a command. |
| Menu as data | The menu definition lives in `default/omarchy/omarchy-menu.jsonc`; the shell reads it. |

For Bluetooth specifically, Omarchy splits *power* from *device* actions:
`omarchy-bluetooth-device` always calls `power_on` first, never assumes the
adapter is up. We mirror that split exactly.

## How DankLinux / DMS does launchers

DMS (the DankMaterialShell desktop) is the "go big" version of the same idea
and a useful contrast:

- The launcher is a **dedicated compiled binary** (`danksearch`), driven over
  IPC: `dms ipc call spotlight toggle` is the keybind.
- Bluetooth, audio, network, etc. live in a QML **Control Center**, not
  scripts.
- Its `scripts/` directory only holds developer tooling (port/release shells),
  not user-facing commands.

The lesson is architectural: **the launcher is a thin dispatch layer over
single-purpose backends.** Omarchy expresses it with shell functions, DMS with
Go + IPC, but both avoid giant monoliths that trap the user in a modal loop.

## Our conventions (this repo)

The bluetooth scripts moved upstream: they live in **bnixos `flakes/bblue`**
and are installed to `~/.local/bin` by the `bblue` home-manager module
(`inputs.bnixos.homeModules.bblue`, wired in `home.nix`). This repo's `bin/`
now holds only dev tools (`hl-mock.lua`, not installed).

### Script layout

```
bnixos flakes/bblue/bin/
├── bt-menu.sh        # thin bl-select menu, dispatches to the below
├── bt-power.sh       # bt-power.sh on|off|toggle|is-on   (omarchy-bluetooth-power)
├── bt-device.sh      # bt-device.sh pair|connect|disconnect|forget <mac>
└── bt-scan.sh        # scan for new devices; prints "name\tmac" per unpaired device
```

`launcher.sh` and `theme-selector.sh` are gone. The app menu is now **blaunch**
(bnixos `flakes/blaunch`, a Quickshell panel) and the theme selector was
retired — switching themes is declarative (edit `btheme.name` in `home.nix`,
`nixos-rebuild switch`).

Rules:

- **Single-purpose commands**: `bt-power.sh`, `bt-device.sh`, `bt-scan.sh`
  do one thing, take explicit args, validate them, and answer with exit codes.
  They never show a menu and never notify.
- **Menus are thin**: `bt-menu.sh` owns `bl-select` and `notify-send`; it
  resolves sibling commands via `SCRIPT_DIR=$(dirname "$0")` — the invocation
  directory, where home-manager puts every script (as symlinks), so siblings
  resolve there. **Never `readlink -f "$0"` for this**: home-manager installs
  each script as its own `/nix/store/...-hm_<name>` wrapper, and the fully
  resolved path's dir is `/nix/store`, which has no sibling scripts.
- **Strict mode**: `set -u` (and `set -euo pipefail` in the single-purpose
  commands) — the menu uses `set -u` only, because a cancelled `bl-select`
  prompt (empty selection / non-zero exit) is a normal menu outcome, not a
  fatal error.
- **Shebang**: `#!/usr/bin/env bash`, a deliberate deviation from Omarchy's
  `#!/bin/bash`, so the scripts reach the right bash in PATH on NixOS.
- **Timeouts everywhere**: every `bluetoothctl` call runs under `timeout`.

### The exit-code menu contract (the bug fix)

`main_menu` returns **non-zero when the top-level menu is dismissed**, and the
script's loop is:

```sh
while main_menu; do :; done
```

A dismissed top-level menu therefore **ends `bt-menu.sh`** — the script can
always be closed by Escape. Submenus (`device_menu`, `scan_and_pair`) return 0
on dismissal so they pop back to the top-level menu instead of quitting. Every
`ask`/`show_menu` failure must propagate a return, never fall through and
relaunch.

If the menu ever seems stuck again, check these rules first.

## The menu tool (bl-select)

Everything that used `fuzzel --dmenu` / `wofi --dmenu` now goes through
`bl-select`, the dmenu mode of the **blaunch** Quickshell launcher (bnixos
`flakes/blaunch`). Contract, matching fuzzel for the scripts:

- `bl-select <prompt> [option...]` — options also read from stdin when none
  are given.
- Exit 0 and prints the chosen line; exit 1 on dismissal (Escape / click
  outside) — the "cancelled prompt is normal" outcome.
- Returns the raw option line including any `<TAB>` separators the caller
  parses itself.

`bl-launch` toggles the app search (`$mod SPACE`). Both talk to the running
blaunch instance over Quickshell's `qs ipc` (via the shared `b-ipc` client
from the `bipc` flake).

### Keybindings

| Key | Action | Source |
|---|---|---|
| `$mod SPACE` | `bl-launch` (ON PATH via the blaunch flake) | `home.nix` `wayland.windowManager.hyprland` bind |
| `$mod B` | bluetui in a floating ghostty (`bblue-tui`; bbinds default) | bnixos `flakes/bbinds` |
| `$mod I` | wifitui in a floating ghostty (`bwifi-tui`; bbinds default) | bnixos `flakes/bbinds` |
| `$mod Q` | close focused window | bnixos `flakes/bbinds` |
| `$mod W` | universal tab-close (Ctrl+Shift+W in terminals per `keybinds.terminals`, Ctrl+W elsewhere) | bnixos `flakes/bbinds` |
| `$mod C` / `$mod V` | universal copy / paste (Ctrl+Shift+C/V in terminals per `keybinds.terminals`, Ctrl+C/V elsewhere) | bnixos `flakes/bbinds` |
| `$mod T` / `$mod N` | universal new tab / new window (class-branching) | `home.nix` `keybinds.override` |

### Testing changes

```sh
bash -n bin/*.sh                       # all scripts parse
nix shell nixpkgs#shellcheck -c shellcheck bin/*.sh
~/.local/bin/bt-power.sh is-on; echo $?  # smoke-test exit contract
```

Then `home-manager switch` to install copies into `~/.local/bin`.

## Reference (Omarchy Bluetooth sources)

- `bin/omarchy-bluetooth-power` — rfkill model, per-controller probe, deadline wait.
- `bin/omarchy-bluetooth-device` — action dispatch, MAC validation, `power_on` first.