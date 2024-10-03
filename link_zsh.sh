#!/usr/bin/env bash 

# Path to your dotfiles and target config directory
ZSHRC_ORIGIN_DIR="$(pwd)/zsh/.zshrc"
ZSHRC_TARGET_DIR="$HOME/.zshrc"

P10K_ORIGIN_DIR="$(pwd)/zsh/.p10k.zsh"
P10K_TARGET_DIR="$HOME/.p10k.zsh"

# Remove existing files if they exist (to avoid link creation errors)
[ -f "$TARGET_ZSHRC" ] && rm "$TARGET_ZSHRC"
[ -f "$TARGET_P10K" ] && rm "$TARGET_P10K"

# Create symlink if not exists
if [ ! -L "$ZSHRC_TARGET_DIR" ]; then
    ln -s "$ZSHRC_ORIGIN_DIR" "$ZSHRC_TARGET_DIR"
    echo "Linked $ZSHRC_ORIGIN_DIR to $ZSHRC_TARGET_DIR"
else
    echo "$ZSHRC_TARGET_DIR already exists as a symlink."
fi

if [ ! -L "$P10K_TARGET_DIR" ]; then
    ln -s "$P10K_ORIGIN_DIR" "$P10K_TARGET_DIR"
    echo "Linked $P10K_ORIGIN_DIR to $P10K_TARGET_DIR"
else
    echo "$P10K_TARGET_DIR already exists as a symlink."
fi