# Declarative Omarchy-style theming for home-manager.
#
# Usage:
#   imports = [ ./themes/theme-module.nix ];
#   themes.theme = "white";          # enum over themes/palettes.nix keys
#
# The selected palette drives every app below; switching themes is a one-line
# change + `home-manager switch` (or nixos-rebuild). See docs/theming.md.

{ config, lib, pkgs, ... }:
let
  palettes = import ./palettes.nix;
  themeName = config.themes.theme;
  palette = palettes.${themeName};
  isLight = palette.mode == "light";

  # Replace {{ token }} placeholders in a template file.
  renderTemplate = template: attrs:
    builtins.foldl'
      (text: name: builtins.replaceStrings [ "{{ ${name} }}" ] [ attrs.${name} ] text)
      template
      (builtins.attrNames attrs);

  # Hex "#rrggbb" -> hyprland "rgb(XXXXXX)" (no commas, 6 hex digits).
  hyprColor = hex: "rgb(${lib.removePrefix "#" hex})";

  # Hex "#rrggbb" -> hyprland "rgba(r, g, b, a)" with alpha 0-1.
  hexToRgba = hex: alpha:
    let
      charValues = builtins.listToAttrs (builtins.genList (i: {
        name = builtins.toString i;
        value = i;
      }) 10) // { a = 10; b = 11; c = 12; d = 13; e = 14; f = 15; };
      charValue = c: charValues.${lib.toLower c};
      digits = lib.removePrefix "#" hex;
      hexToDec = s: builtins.foldl'
        (acc: c: acc * 16 + charValue c)
        0
        (lib.stringToCharacters s);
      # "0.8" style alpha (hundredths), avoiding Nix float coercion noise.
      fmtAlpha = a:
        let p = builtins.floor (a * 100); t = p / 10;
        in if p == 100 then "1.0"
           else if t * 10 == p then "0.${toString t}"
           else "0.${toString p}";
    in
    "rgba(${toString (hexToDec (lib.substring 0 2 digits))}, ${toString (hexToDec (lib.substring 2 2 digits))}, ${toString (hexToDec (lib.substring 4 2 digits))}, ${fmtAlpha alpha})";

  # Hex "#rrggbb" -> ghostty hex without the leading '#'
  bareHex = hex: lib.removePrefix "#" hex;

  render = tplPath: builtins.readFile tplPath;

  btopTheme = renderTemplate (render ./templates/btop.theme.tpl) palette;
  btopConf = renderTemplate (render ./templates/btop.conf.tpl) { color_theme = themeName; };
  waybarStyle = renderTemplate (render ./templates/waybar-style.css.tpl) palette;
  wofiStyle = renderTemplate (render ./templates/wofi-style.css.tpl) palette;

  # Theme wallpaper: palettes carry a `wallpaper` key naming a file in
  # wallpapers/.
  wallpaperPath = "${../wallpapers}/${palette.wallpaper}";

  hyprpaperConf = ''
    preload = ${wallpaperPath}
    wallpaper = ,${wallpaperPath}
    splash = false
  '';

  hyprlockConf = renderTemplate (render ./templates/hyprlock.conf.tpl) ({
    # Omarchy lock surface: theme background at 80% alpha, accent border,
    # palette foreground text, palette red on failure.
    lockInner = hexToRgba palette.background 0.8;
    lockOuter = hexToRgba palette.accent 1.0;
    lockCheck = hexToRgba palette.green 1.0;
    lockFail = hexToRgba palette.red 1.0;
    lockFont = hexToRgba palette.foreground 1.0;
    lockBg = wallpaperPath;
  });

  # ANSI 0-15 for ghostty, built from the Omarchy palette keys.
  ghosttyPalette = [
    "0=${bareHex palette.dark_background}"
    "1=${bareHex palette.red}"
    "2=${bareHex palette.green}"
    "3=${bareHex palette.yellow}"
    "4=${bareHex palette.blue}"
    "5=${bareHex palette.magenta}"
    "6=${bareHex palette.cyan}"
    "7=${bareHex palette.lighter_background}"
    "8=${bareHex palette.muted}"
    "9=${bareHex palette.bright_red}"
    "10=${bareHex palette.bright_green}"
    "11=${bareHex palette.bright_yellow}"
    "12=${bareHex palette.bright_blue}"
    "13=${bareHex palette.bright_magenta}"
    "14=${bareHex palette.bright_cyan}"
    "15=${bareHex palette.background}"
  ];

  ghosttyTheme = {
    background = bareHex palette.background;
    foreground = bareHex palette.foreground;
    cursor-color = bareHex palette.bright_foreground;
    selection-background = bareHex palette.selection;
    selection-foreground = bareHex palette.foreground;
    palette = ghosttyPalette;
  };
in
{
  options.themes.theme = lib.mkOption {
    type = lib.types.enum (builtins.attrNames palettes);
    default = "white";
    description = "Active Omarchy-style theme, chosen from themes/palettes.nix.";
  };

  config = {
    # Waybar
    xdg.configFile."waybar/config".source = ../config/waybar/config;
    xdg.configFile."waybar/config".force = true;
    xdg.configFile."waybar/style.css".text = waybarStyle;
    xdg.configFile."waybar/style.css".force = true;
    xdg.configFile."waybar/scripts".source = ../config/waybar/scripts;
    xdg.configFile."waybar/scripts".recursive = true;
    xdg.configFile."waybar/scripts".force = true;

    # wofi
    xdg.configFile."wofi/style.css".text = wofiStyle;
    xdg.configFile."wofi/style.css".force = true;

    # btop
    xdg.configFile."btop/btop.conf".text = btopConf;
    xdg.configFile."btop/btop.conf".force = true;
    xdg.configFile."btop/themes/${themeName}.theme".text = btopTheme;

    # hyprlock (Omarchy-style, themed from the palette)
    xdg.configFile."hypr/hyprlock.conf".text = hyprlockConf;
    xdg.configFile."hypr/hyprlock.conf".force = true;

    # hyprpaper (wallpaper follows the active theme)
    xdg.configFile."hypr/hyprpaper.conf".text = hyprpaperConf;
    xdg.configFile."hypr/hyprpaper.conf".force = true;

    # Ghostty
    programs.ghostty.themes.${themeName} = ghosttyTheme;
    programs.ghostty.settings.theme = themeName;

    # Hyprland borders follow the palette (foreground = active, muted = inactive)
    wayland.windowManager.hyprland.settings.general."col.active_border" = hyprColor palette.foreground;
    wayland.windowManager.hyprland.settings.general."col.inactive_border" = hyprColor palette.muted;

    # GTK
    gtk.theme = {
      name = if isLight then "Adwaita" else "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };
}
