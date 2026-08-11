#!/usr/bin/env bash

# Bluetooth device control — modeled after Omarchy's omarchy-bluetooth-device.
# Single-purpose command, no UI: exit code is the interface.
#
# Usage:
#   bt-device.sh pair|connect|disconnect|forget <address>

set -euo pipefail

usage() {
  echo "Usage: bt-device.sh [pair|connect|disconnect|forget] <address>" >&2
  exit 1
}

action=${1:-}
address=${2:-}

[[ $action == "pair" || $action == "connect" || $action == "disconnect" || $action == "forget" ]] || usage
[[ $address =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] || usage

# Bluetooth refuses to power an adapter up while an rfkill soft block is set,
# and turning the adapter on is a precondition for every action below. Resolve
# the sibling command from this script's invocation directory, not PATH (home-
# manager installs every script as its own store wrapper, so `readlink -f $0`
# would land in /nix/store with no siblings).
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

power_on() {
  "$SCRIPT_DIR/bt-power.sh" on
}

trust_device() {
  bluetoothctl trust "$address" >/dev/null 2>&1 || true
}

case "$action" in
  pair)
    power_on
    rc=0
    timeout 30s bluetoothctl pair "$address" >/dev/null 2>&1 || rc=$?
    trust_device
    timeout 20s bluetoothctl connect "$address" >/dev/null 2>&1 || rc=$?
    exit "$rc"
    ;;
  connect)
    power_on
    trust_device
    rc=0
    timeout 20s bluetoothctl connect "$address" >/dev/null 2>&1 || rc=$?
    exit "$rc"
    ;;
  disconnect)
    timeout 10s bluetoothctl disconnect "$address" >/dev/null 2>&1 || true
    ;;
  forget)
    power_on
    timeout 10s bluetoothctl disconnect "$address" >/dev/null 2>&1 || true
    timeout 10s bluetoothctl remove "$address" >/dev/null 2>&1 || true
    ;;
esac