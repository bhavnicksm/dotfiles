{ lib }:

# Managed dotfiles -> ~/.config/<name>
# starship.toml is intentionally absent: programs.starship already owns
# ~/.config/starship.toml via the fromTOML settings in home.nix.
#
# wofi and btop are NOT listed here: they are generated from the active
# theme by themes/theme-module.nix (see themes/palettes.nix).
# hypr is likewise not listed: hyprpaper.conf (wallpaper) is themed and
# hyprland.lua comes from the wayland.windowManager.hyprland module.
# The status bar (bbar) is not listed either: it is owned by bnixos
# (flakes/bbar, a Quickshell bar) and wired via the bbar home-module.
lib.genAttrs [ "gtk-3.0" ] (name: {
  source = ./config/${name};
  recursive = true;
  force = true;
})
// {
  "pavucontrol.ini" = {
    source = ./config/pavucontrol.ini;
    force = true;
  };
}