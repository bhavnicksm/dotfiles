{ lib }:

# Managed dotfiles -> ~/.config/<name>
# starship.toml is intentionally absent: programs.starship already owns
# ~/.config/starship.toml via the fromTOML settings in home.nix (colors come
# from btheme).
#
# btop is not listed here: it is generated from the active theme by btheme
# (bnixos flakes/btheme). wofi is gone entirely — the launcher landed on
# blaunch (bnixos flakes/blaunch), which replaced both the fuzzel app search
# and the wofi/fuzzel --dmenu prompts.
# hypr is likewise not listed: hyprpaper.conf/hyprlock.conf are themed by
# btheme, hyprsunset.conf ships with bnight, and hyprland.lua comes from the
# wayland.windowManager.hyprland module.
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
}