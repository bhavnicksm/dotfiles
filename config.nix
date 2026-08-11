{ lib }:

# Managed dotfiles -> ~/.config/<name>
# starship.toml is intentionally absent: programs.starship already owns
# ~/.config/starship.toml via the fromTOML settings in home.nix.
lib.genAttrs [ "waybar" "wofi" "btop" "gtk-3.0" "hypr" ] (name: {
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