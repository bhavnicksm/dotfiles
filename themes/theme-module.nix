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
  wofiStyle = renderTemplate (render ./templates/wofi-style.css.tpl) palette;

  # Theme wallpaper: palettes carry a `wallpaper` key naming a file in
  # wallpapers/.
  wallpaperPath = "${../wallpapers}/${palette.wallpaper}";

  # hyprpaper config lives in themes/templates/hyprpaper.conf.tpl (hyprpaper
  # >= 0.8 block format); only the themed wallpaper path is injected here.
  hyprpaperConf = renderTemplate (render ./templates/hyprpaper.conf.tpl) { wallpaper = wallpaperPath; };

  hyprlockConf = renderTemplate (render ./templates/hyprlock.conf.tpl) ({
    # Omarchy lock surface: theme background at 80% alpha, accent border,
    # palette foreground text, palette red on failure.
    lockInner = hexToRgba palette.background 0.85;
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

  # ---- opencode TUI theme (see https://opencode.ai/docs/themes) ----
  clampByte = n: if n < 0 then 0 else if n > 255 then 255 else n;
  hexByte = n: let s = lib.toHexString (builtins.floor (clampByte n)); in if lib.stringLength s == 1 then "0${s}" else s;
  rgbHex = r: g: b: "#${hexByte r}${hexByte g}${hexByte b}";
  channels = hex:
    let d = lib.removePrefix "#" hex;
        dec = s: builtins.foldl'
          (acc: c: acc * 16 + (builtins.listToAttrs (builtins.genList (i: {
            name = builtins.toString i;
            value = i;
          }) 10) // { a = 10; b = 11; c = 12; d = 13; e = 14; f = 15; }).${lib.toLower c})
          0 (lib.stringToCharacters s);
    in {
      r = dec (lib.substring 0 2 d);
      g = dec (lib.substring 2 2 d);
      b = dec (lib.substring 4 2 d);
    };
  # Mix a hex toward white by `amt` (0-1); for dark-mode variants.
  mixWhite = hex: amt:
    let c = channels hex;
        m = n: n * (1.0 - amt) + 255.0 * amt;
    in rgbHex (m c.r) (m c.g) (m c.b);
  # Scale the palette background down toward black by `f`; dark-mode panels.
  darkBg = f:
    let c = channels palette.background;
    in rgbHex (c.r * f) (c.g * f) (c.b * f);
  # Dark and light variants for every theme role.
  d = dark: light: { inherit dark light; };
  # Dark-mode surface derived from the (light) palette background.
  darkSurface = darkBg 0.11;
  darkOnDark = amt: mixWhite darkSurface amt;
  oc = {
    "$schema" = "https://opencode.ai/theme.json";
    defs = {
      bg = palette.background;
      bgPanel = palette.dark_background;
      bgElement = palette.darker_background;
      fg = palette.foreground;
      muted = palette.muted;
      accent = palette.accent;
      selection = palette.selection;
      red = palette.red;
      yellow = palette.yellow;
      green = palette.green;
      cyan = palette.cyan;
      blue = palette.blue;
      magenta = palette.magenta;
    };
    theme = {
      primary = d "accent" "accent";
      secondary = d "selection" "selection";
      accent = d "accent" "accent";
      error = d (mixWhite palette.red 0.45) "red";
      warning = d (mixWhite palette.yellow 0.45) "yellow";
      success = d (mixWhite palette.green 0.45) "green";
      info = d (mixWhite palette.cyan 0.45) "cyan";
      text = d (darkOnDark 0.9) "fg";
      textMuted = d (darkOnDark 0.6) "muted";
      background = d (darkBg 0.11) "bg";
      backgroundPanel = d (darkBg 0.15) "bgPanel";
      backgroundElement = d (darkBg 0.19) "bgElement";
      border = d (darkBg 0.22) "bgElement";
      borderActive = d (darkOnDark 0.55) "accent";
      borderSubtle = d (darkBg 0.11) "bgElement";
      diffAdded = d "#3fb950" "#1a7f37";
      diffRemoved = d "#f85149" "#cf222e";
      diffContext = d (darkOnDark 0.6) "muted";
      diffHunkHeader = d (darkOnDark 0.7) "accent";
      diffHighlightAdded = d "#3fb950" "#1a7f37";
      diffHighlightRemoved = d "#f85149" "#cf222e";
      diffAddedBg = d "#12251c" "#dafbe1";
      diffRemovedBg = d "#2d1b1b" "#ffebe9";
      diffContextBg = d (darkBg 0.15) "bgPanel";
      diffLineNumber = d (darkOnDark 0.5) "muted";
      diffAddedLineNumberBg = d "#12251c" "#dafbe1";
      diffRemovedLineNumberBg = d "#2d1b1b" "#ffebe9";
      markdownText = d (darkOnDark 0.9) "fg";
      markdownHeading = d (darkOnDark 0.75) "accent";
      markdownLink = d (darkOnDark 0.7) "accent";
      markdownLinkText = d (darkOnDark 0.7) "accent";
      markdownCode = d (mixWhite palette.cyan 0.45) "cyan";
      markdownBlockQuote = d (darkOnDark 0.6) "muted";
      markdownEmph = d (mixWhite palette.yellow 0.45) "yellow";
      markdownStrong = d (darkOnDark 0.9) "fg";
      markdownHorizontalRule = d (darkBg 0.3) "bgElement";
      markdownListItem = d (darkOnDark 0.75) "accent";
      markdownListEnumeration = d (darkOnDark 0.75) "accent";
      markdownImage = d (darkOnDark 0.7) "accent";
      markdownImageText = d (darkOnDark 0.6) "muted";
      markdownCodeBlock = d (darkOnDark 0.85) "fg";
      syntaxComment = d (darkOnDark 0.55) "muted";
      syntaxKeyword = d (darkOnDark 0.7) "accent";
      syntaxFunction = d (mixWhite palette.blue 0.5) "blue";
      syntaxVariable = d (darkOnDark 0.9) "fg";
      syntaxString = d (mixWhite palette.green 0.5) "green";
      syntaxNumber = d (mixWhite palette.magenta 0.5) "magenta";
      syntaxType = d (mixWhite palette.cyan 0.45) "cyan";
      syntaxOperator = d (darkOnDark 0.7) "accent";
      syntaxPunctuation = d (darkOnDark 0.85) "fg";
    };
  };
  opencodeThemeName = themeName;
in
{
  options.themes.theme = lib.mkOption {
    type = lib.types.enum (builtins.attrNames palettes);
    default = "white";
    description = "Active Omarchy-style theme, chosen from themes/palettes.nix.";
  };

  config = {
    # bbar (bnixos flakes/bbar) — the Quickshell status bar. Its 7-color
    # palette comes from the active Omarchy palette (a strict subset of the
    # full palette's keys), so the bar follows themes.theme like everything
    # else.
    bbar.palette = {
      background = palette.background;
      foreground = palette.foreground;
      accent = palette.accent;
      muted = palette.muted;
      selection = palette.selection;
      red = palette.red;
      yellow = palette.yellow;
      green = palette.green;
    };

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

    # opencode TUI follows the active theme
    xdg.configFile."opencode/themes/${opencodeThemeName}.json" = {
      text = builtins.toJSON oc;
      force = true;
    };
    xdg.configFile."opencode/tui.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/tui.json";
        theme = opencodeThemeName;
      };
      force = true;
    };

    # Ghostty
    programs.ghostty.themes.${themeName} = ghosttyTheme;
    programs.ghostty.settings.theme = themeName;

    # Hyprland borders follow the palette (foreground = active, muted = inactive).
    # Lua config reads colors as "rgba(r,g,b,a)" strings (hyprlang's comma-less
    # "rgb(XXXXXX)" is not valid in ~/.config/hypr/hyprland.lua).
    wayland.windowManager.hyprland.settings.config.general."col.active_border" = hexToRgba palette.foreground 1.0;
    wayland.windowManager.hyprland.settings.config.general."col.inactive_border" = hexToRgba palette.muted 1.0;

    # GTK
    gtk.theme = {
      name = if isLight then "Adwaita" else "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };
}
