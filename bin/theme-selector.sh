#!/usr/bin/env bash

WAYBAR_DIR="$HOME/.config/waybar"
STYLECSS="$WAYBAR_DIR/style.css"
CONFIG="$WAYBAR_DIR/config"

# Show theme options (only one for now)
theme=$(printf "Gruvbox Light" | fuzzel --dmenu --prompt="Theme: ")

case "$theme" in
    "Gruvbox Light")
        # Reload waybar with current theme
        pkill waybar && waybar &
        notify-send "BnixOS Theme" "Gruvbox Light theme active"
        ;;
esac
