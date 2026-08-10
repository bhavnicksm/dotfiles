#!/usr/bin/env bash

# First level menu - choose category
choice=$(printf "🚀 Apps\n🎨 Themes" | fuzzel --dmenu --prompt="Select: ")

case "$choice" in
    "🚀 Apps")
        # Launch normal fuzzel application launcher
        fuzzel
        ;;
    "🎨 Themes")
        # Launch theme selector
        ~/.bnixos/bin/theme-selector.sh
        ;;
esac
