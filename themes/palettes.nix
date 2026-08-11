# Omarchy-style declarative theme palettes.
#
# Keys follow Omarchy's colors.toml semantics exactly:
#   mode / accent / selection / muted / background / dark_background /
#   darker_background / lighter_background / foreground / dark_foreground /
#   light_foreground / bright_foreground / red..magenta (+bright_*)
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
  };
}