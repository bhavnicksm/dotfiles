#!/usr/bin/env bash

# Path to your dotfiles and target config directory
DOTFILES_DIR="$(pwd)/neovim/.config/nvim"
TARGET_DIR="$HOME/.config/nvim"

# Create symlink if not exists
if [ ! -L "$TARGET_DIR" ]; then
    ln -s "$DOTFILES_DIR" "$TARGET_DIR"
    echo "Linked $DOTFILES_DIR to $TARGET_DIR"
else
    echo "$TARGET_DIR already exists as a symlink."
fi
