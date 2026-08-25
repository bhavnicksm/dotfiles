{ lib }:

# Managed dotfiles -> ~/.config/<name>
# starship.toml is intentionally absent: programs.starship already owns
# ~/.config/starship.toml via the fromTOML settings in home.nix.
#
# btop is not listed here: it is generated from the active theme by
# themes/theme-module.nix (see themes/palettes.nix). wofi is gone entirely —
# the launcher landed on blaunch (bnixos flakes/blaunch), which replaced both
# the fuzzel app search and the wofi/fuzzel --dmenu prompts.
# hypr is likewise not listed: hyprpaper.conf (wallpaper) is themed and
# hyprland.lua comes from the wayland.windowManager.hyprland module.
# The status bar (bbar) and launcher (blaunch) are not listed either: they
# are owned by bnixos (flakes/bbar, flakes/blaunch, Quickshell) and wired via
# their home-modules.
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

  # Night light profiles -> ~/.config/hypr/hyprsunset.conf (hyprsunset
  # discovers its config through Hyprutils, same dir as hyprland.lua).
  "hypr/hyprsunset.conf" = {
    source = ./config/hyprsunset.conf;
    force = true;
  };
}