{ lib }:

# Managed dotfiles -> ~/.config/<name>
# starship.toml is intentionally absent: programs.starship already owns
# ~/.config/starship.toml via the fromTOML settings in home.nix.
#
# waybar, wofi and btop are NOT listed here: they are generated from the
# active theme by themes/theme-module.nix (see themes/palettes.nix).
# hypr is likewise not listed: hyprpaper.conf (wallpaper) is themed and
# hyprland.lua comes from the wayland.windowManager.hyprland module.
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