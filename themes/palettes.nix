# Omarchy-style declarative theme palettes.
#
# Keys follow Omarchy's colors.toml semantics exactly:
#   mode / accent / selection / muted / background / dark_background /
#   darker_background / lighter_background / foreground / dark_foreground /
#   light_foreground / bright_foreground / red..magenta (+bright_*)
#
# Optional per-theme extras consumed by btheme (bnixos flakes/btheme):
#   wallpaper — file name in wallpapers/; resolved to a store path by
#               home.nix before the catalog is handed to btheme.
#   starship  — prompt segment colors (color_fg0/color_bg1/color_bg3 +
#               color_{orange,yellow,green,aqua,blue,purple,red}). Without
#               it btheme falls back to a monochrome-safe mapping of the
#               Omarchy keys.
#
# The "white" theme is a verbatim port of Omarchy's themes/white/colors.toml.
# See docs/theming.md for how to add themes and how palette keys map to apps.

{
  white = {
    # Port of Omarchy themes/white/colors.toml
    mode = "light";

    # Default wallpaper for this theme (relative to wallpapers/).
    wallpaper = "golden-gate.png";

    accent = "#6e6e6e";
    selection = "#c0c0c0";
    muted = "#808080";

    background = "#ffffff";
    dark_background = "#f5f5f5";
    darker_background = "#e8e8e8";
    lighter_background = "#c0c0c0";

    foreground = "#000000";
    dark_foreground = "#c0c0c0";
    light_foreground = "#000000";
    bright_foreground = "#000000";

    red = "#2a2a2a";
    yellow = "#4a4a4a";
    green = "#3a3a3a";
    cyan = "#3e3e3e";
    blue = "#1a1a1a";
    magenta = "#2e2e2e";

    bright_red = "#2a2a2a";
    bright_yellow = "#4a4a4a";
    bright_green = "#3a3a3a";
    bright_cyan = "#3e3e3e";
    bright_blue = "#1a1a1a";
    bright_magenta = "#2e2e2e";

    # Starship prompt segment colors: the Flexoki-light set the prompt was
    # originally recolored to (preserved verbatim across theme switches).
    starship = {
      color_fg0 = "#100F0F";
      color_bg1 = "#F2F0E5";
      color_bg3 = "#DAD8CE";
      color_blue = "#4385BE";
      color_aqua = "#24837B";
      color_green = "#879A39";
      color_orange = "#DA702C";
      color_purple = "#8B7EC8";
      color_red = "#D14D41";
      color_yellow = "#D0A215";
    };
  };

  gruvbox-light = {
    # The palette previously hard-coded across this flake's configs.
    mode = "light";

    # Default wallpaper for this theme (relative to wallpapers/).
    wallpaper = "golden-gate.png";

    accent = "#076678";
    selection = "#d5c4a1";
    muted = "#928374";

    background = "#ffffff";
    dark_background = "#fbf1c7";
    darker_background = "#ebdbb2";
    lighter_background = "#f9f5d7";

    foreground = "#3c3836";
    dark_foreground = "#665c54";
    light_foreground = "#3c3836";
    bright_foreground = "#282828";

    red = "#9d0006";
    yellow = "#b57614";
    green = "#79740e";
    cyan = "#427b58";
    blue = "#076678";
    magenta = "#8f3f71";

    bright_red = "#cc241d";
    bright_yellow = "#d79921";
    bright_green = "#98971a";
    bright_cyan = "#689d6a";
    bright_blue = "#458588";
    bright_magenta = "#b16286";

    # Starship prompt segment colors: gruvbox hues (bright_* variants) on
    # the cream surfaces, dark fg for contrast on light segment backgrounds.
    starship = {
      color_fg0 = "#3c3836";
      color_bg1 = "#ebdbb2";
      color_bg3 = "#d5c4a1";
      color_blue = "#458588";
      color_aqua = "#689d6a";
      color_green = "#98971a";
      color_orange = "#d65d0e";
      color_purple = "#b16286";
      color_red = "#cc241d";
      color_yellow = "#d79921";
    };
  };
}