#!/usr/bin/env bash

# Scan for Bluetooth devices to pair. Single-purpose command: prints one line
# per *unpaired* device (name, TAB, address) so the caller can render a menu.
# Exit codes: 0 = at least one unpaired device found, 1 = none found.
#
# Usage:
#   bt-scan.sh [seconds]

set -euo pipefail

SCAN_SECONDS=${1:-7}

bluetoothctl scan on >/dev/null 2>&1 &
scan_pid=$!
sleep "$SCAN_SECONDS"
timeout 3s bluetoothctl scan off >/dev/null 2>&1 || true
kill "$scan_pid" 2>/dev/null || true
wait "$scan_pid" 2>/dev/null || true

macs=()
while read -r mac name; do
  [[ -n $mac ]] || continue
  # Skip devices we already know: the menu only offers unknowns.
  if ! bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes"; then
    printf '%s\t%s\n' "$name" "$mac"
    macs+=("$mac")
  fi
done < <(bluetoothctl devices | sed 's/^Device //')

[[ ${#macs[@]} -gt 0 ]]