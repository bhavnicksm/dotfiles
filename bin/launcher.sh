#!/usr/bin/env bash

# First level menu - choose category. Sibling scripts are resolved from this
# script's own location (works from the repo or from ~/.local/bin).

set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

MENU_BIN=${LAUNCHER_MENU_BIN:-$(command -v fuzzel || command -v wofi || true)}

[[ -n $MENU_BIN ]] || {
  notify-send -a launcher "Launcher" "No fuzzel/wofi found — install one" 2>/dev/null || true
  exit 1
}

choice=$(printf "🚀 Apps\n🎨 Themes" | "$MENU_BIN" --dmenu --prompt="Select: ") || exit 0

case "$choice" in
    "🚀 Apps")
        # Launch normal fuzzel application launcher
        "$MENU_BIN"
        ;;
    "🎨 Themes")
        # Launch theme selector
        "$SCRIPT_DIR/theme-selector.sh"
        ;;
esac
