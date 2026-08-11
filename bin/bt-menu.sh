#!/usr/bin/env bash

# Bluetooth menu — thin fuzzel/wofi front end over the single-purpose bt-*
# commands (bt-power, bt-device, bt-scan), modeled after Omarchy's menu style.
#
# Exit-code contract (see docs/launchers-and-scripts.md):
#   - a dismissed top-level menu (Escape) ends this script
#   - a dismissed submenu pops back to the top-level menu
#   - each action just runs a bt-* command and notifies about the outcome

set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

MENU_BIN=${BT_MENU_BIN:-$(command -v fuzzel || command -v wofi || true)}
NOTIFY_BIN=${BT_MENU_NOTIFY:-notify-send}

[[ -n $MENU_BIN ]] || {
  notify-send -a bt-menu "Bluetooth" "No fuzzel/wofi found — install one" 2>/dev/null || true
  exit 1
}

ask() {
  local prompt=$1
  shift
  [[ $# -gt 0 ]] || return 1
  "$MENU_BIN" --dmenu --prompt="$prompt " <<< "$(
    printf '%s\n' "$@"
  )"
}

notify() {
  command -v "$NOTIFY_BIN" >/dev/null 2>&1 && "$NOTIFY_BIN" -a bt-menu "Bluetooth" "$1"
}

# Labels are the display strings, actions are the dispatcher tokens. Returns
# 1 on dismissal at the current level; the caller decides whether that pops
# back (submenu) or exits (top-level menu).
show_menu() {
  local prompt=$1
  # Namerefs: the caller passes the literal array names `labels` / `actions`,
  # so the locals must not share those names (a `local -n labels=labels`
  # would be a circular reference).
  local -n lbls=$2
  local -n acts=$3
  local sel i
  sel=$(ask "$prompt" "${lbls[@]}")
  [[ -n $sel ]] || return 1
  for i in "${!lbls[@]}"; do
    [[ ${lbls[$i]} == "$sel" ]] || continue
    sel_action="${acts[$i]}"
    return 0
  done
  return 1
}

is_powered() {
  "$SCRIPT_DIR/bt-power.sh" is-on
}

device_connected() {
  timeout 2s bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes"
}

pair_device() {
  local mac=$1
  notify "Pairing with ${mac}… accept the prompt on your device if asked"
  if "$SCRIPT_DIR/bt-device.sh" pair "$mac"; then
    notify "Paired"
  else
    notify "Pairing/connection failed — is the device in pairing mode?"
  fi
}

forget_device() {
  local mac=$1
  "$SCRIPT_DIR/bt-device.sh" forget "$mac"
  notify "Forgot $mac"
}

scan_and_pair() {
  notify "Scanning for new devices…"
  local -a labels=()
  local -a macs=()
  local name mac sel

  while read -r name mac; do
    [[ -n $mac ]] || continue
    labels+=("$name  ($mac)")
    macs+=("$mac")
  done < <("$SCRIPT_DIR/bt-scan.sh" 7)

  if [[ ${#macs[@]} -eq 0 ]]; then
    notify "No new devices found"
    return 0
  fi

  sel=$(ask "Pair new device" "${labels[@]}")
  [[ -n $sel ]] || return 0 # dismissed → back to the top-level menu

  local i
  for i in "${!labels[@]}"; do
    [[ ${labels[$i]} == "$sel" ]] || continue
    pair_device "${macs[$i]}"
    return 0
  done
}

device_menu() {
  local mac=$1 name=$2
  local -a labels=()
  local -a actions=()
  local sel_action

  while :; do
    labels=()
    actions=()
    if device_connected "$mac"; then
      labels+=("Disconnect")
      actions+=("disconnect")
    elif is_powered; then
      labels+=("Connect")
      actions+=("connect")
    else
      labels+=("Pair")
      actions+=("pair")
    fi
    labels+=("Forget Device")
    actions+=("forget")

    if ! show_menu "$name" labels actions; then
      return 0 # dismissed → back to the top-level menu
    fi

    case "$sel_action" in
      connect)
        if "$SCRIPT_DIR/bt-device.sh" connect "$mac"; then
          notify "$name connected"
        else
          notify "Could not connect $name"
        fi
        ;;
      disconnect)
        "$SCRIPT_DIR/bt-device.sh" disconnect "$mac"
        notify "$name disconnected"
        ;;
      pair)
        pair_device "$mac"
        ;;
      forget)
        forget_device "$mac"
        return 0
        ;;
    esac
  done
}

main_menu() {
  local -a labels=()
  local -a actions=()
  local mac name sel_action

  if is_powered; then
    labels+=("Bluetooth: On")
  else
    labels+=("Bluetooth: Off")
  fi
  actions+=("power")
  labels+=("Pair New Device")
  actions+=("scan")

  while read -r mac name; do
    [[ -n $mac ]] || continue
    if device_connected "$mac"; then
      labels+=("$name (connected)")
    else
      labels+=("$name")
    fi
    actions+=("device:$mac|$name")
  done < <(bluetoothctl devices | sed 's/^Device //')

  if ! show_menu "Bluetooth" labels actions; then
    return 1 # dismissed at the top level → quit
  fi

  case "$sel_action" in
    power)
      if is_powered; then
        "$SCRIPT_DIR/bt-power.sh" off
        notify "Bluetooth off"
      else
        if "$SCRIPT_DIR/bt-power.sh" on; then
          notify "Bluetooth on"
        else
          notify "Could not power Bluetooth on"
        fi
      fi
      ;;
    scan)
      scan_and_pair
      ;;
    device:*)
      local d="${sel_action#device:}"
      local mac="${d%%|*}"
      local name="${d#*|}"
      device_menu "$mac" "$name"
      ;;
  esac
}

# Loop while the menu keeps being useful; main_menu returns 1 (non-zero) when
# the top-level menu is dismissed, and that ends the loop — the menu must
# always be closable.
while main_menu; do :; done