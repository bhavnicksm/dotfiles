#!/usr/bin/env bash

# Declarative theme switcher.
#
# Omarchy-style theming lives in themes/palettes.nix and is selected with
# `themes.theme = "<name>"` in home.nix. This script edits that one line and
# rebuilds — no runtime sed on generated configs, so the switch is still
# atomic and reproducible via the nix store.
#
# Usage:
#   theme-selector.sh            # pick from themes/palettes.nix (fuzzel)
#   theme-selector.sh <name>     # set a specific theme

DOTFILES="$(readlink -f ~/dotfiles)"
HOME_NIX="$DOTFILES/home.nix"
PALETTES="$DOTFILES/themes/palettes.nix"

set -euo pipefail

themes=$(grep -oP '^  \K[a-z0-9-]+(?= = \{)' "$PALETTES")
current=$(grep -oP 'themes\.theme = "\K[^"]+' "$HOME_NIX")

if [[ $# -ge 1 ]]; then
    selected="$1"
else
    selected=$(printf '%s\n' "$themes" | fuzzel --dmenu --prompt="Theme (current: $current): " )
fi

grep -qx "$selected" <<<"$themes" || {
    echo "Unknown theme '$selected'. Available:"
    printf '  %s\n' "$themes"
    exit 1
}

if [[ $selected == "$current" ]]; then
    echo "Theme '$selected' is already active."
    exit 0
fi

sed -i "s/themes\.theme = \"[^\"]*\"/themes.theme = \"$selected\"/" "$HOME_NIX"

echo "Switched themes.theme to '$selected'. Rebuilding..."
sudo nixos-rebuild switch --flake "$DOTFILES"
notify-send "Theme" "$selected applied"