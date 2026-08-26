# Declarative Omarchy-style theming

This flake recreates how [Omarchy](https://github.com/basecamp/omarchy) themes
its UI, but declaratively: a theme is a *palette*, and every app config is
generated from it at build time. Switching themes is a one-line change plus a
rebuild — there is no runtime config surgery.

## How Omarchy theming works (the model we borrow)

Omarchy stores each theme as a directory (`themes/<name>/`) holding a
`colors.toml` palette plus per-app overrides. Activating a theme
(`omarchy-theme-set <name>`) stages the theme, renders template files
(`default/themed/*.tpl`) into concrete configs for hyprland, ghostty, btop,
and so on, then hot-reloads them. The bar's colors came from a tiny template:

```css
@define-color foreground {{ foreground }};
@define-color background {{ background }};
```

So the *bar* is just layout CSS; the *theme* is the palette. The "white"
theme's palette (`themes/white/colors.toml`) is monochrome light:

```toml
mode = "light"
accent = "#6e6e6e"   selection = "#c0c0c0"   muted = "#808080"
background = "#ffffff"   foreground = "#000000"
red = "#2a2a2a"  yellow = "#4a4a4a"  green = "#3a3a3a"
cyan = "#3e3e3e" blue = "#1a1a1a"    magenta = "#2e2e2e"
```

## This flake's model

- `themes/palettes.nix` — the palette catalog (consumer-owned colors).
  Keys mirror Omarchy's `colors.toml` semantics (`mode`, `accent`,
  `selection`, `muted`, `background`, `foreground`, semantic colors,
  `bright_*`). Optional extras per theme: `wallpaper` (file name in
  `wallpapers/`, resolved to a store path by home.nix) and `starship`
  (prompt segment colors; without it btheme falls back to a monochrome-safe
  mapping of the Omarchy keys).
- bnixos `flakes/btheme` — the theming engine itself, upstream since the
  btheme migration. It exposes `btheme.themes` (the catalog) +
  `btheme.name`, and renders every themed surface: ghostty, btop, hyprlock,
  hyprpaper, opencode, gtk, starship colors, hyprland borders + desktop
  look defaults. Templates live upstream (`flakes/btheme/templates/`).

### Selecting a theme

```nix
# home.nix
btheme.name = "white";   # any key in themes/palettes.nix
```

then:

```sh
nixos-rebuild switch --flake ~/dotfiles
```

The old `theme-selector.sh` flow is retired — switching themes is fully
declarative (edit that one line, rebuild).

### What each app reads

| App | Source | Palette keys used |
|-----|--------|-------------------|
| bbar / blaunch / bnotif | bnixos `flakes/b*` reading `config.btheme.palette` | `background`, `foreground`, `accent`, `muted`, `selection`, `red`, `yellow`, `green` |
| bnixvim | bnixos `flakes/bnixvim` reading `config.btheme.palette` | the 7 above + `blue`, `cyan`, `magenta` |
| Hyprland | btheme → `wayland.windowManager.hyprland.settings` | `foreground` → active border, `muted` → inactive border (+ look defaults) |
| Ghostty | btheme → `programs.ghostty.themes.<name>` | `background`, `foreground`, `cursor`, `selection`, 16-color ANSI palette |
| Starship | btheme → `programs.starship.settings.palettes.<name>` | `starship` extra or structural fallback |
| btop | btheme → `~/.config/btop/themes/<name>.theme` + `btop/btop.conf` | all semantic colors |
| hyprlock / hyprpaper | btheme templates (needs `wallpaper` on the palette) | background/accent/red/green/foreground + wallpaper |
| GTK | btheme → `gtk.theme` | `mode` → `Adwaita` (light) / `Adwaita-dark` |

## Adding a theme

1. Add a block to `themes/palettes.nix` following Omarchy's key names. A
   minimal entry needs at least `mode`, `background`, `foreground`, `accent`,
   `muted`, `selection`, and the semantic colors your apps reference.
2. Optionally add `wallpaper` and `starship` extras (see above).
3. Set `btheme.name = "<key>";` in home.nix and rebuild.

Because the palette keys are shared, one new palette themes every app at once.

## Customizing generated output

The templates moved upstream with btheme — they live in
`bnixos flakes/btheme/templates/` (`btop.theme.tpl`, `btop.conf.tpl`,
`hyprlock.conf.tpl`, `hyprpaper.conf.tpl`). The bar/launcher/notification
engines are also upstream (`flakes/bbar`, `flakes/blaunch`,
`flakes/bnotif`), themed from `config.btheme.palette`. Edit those in
bnixos, not here.

Static, theme-independent config stays under `config/` and is wired through
`config.nix` (currently `gtk-3.0` bookmarks, `pavucontrol.ini`;
`starship.toml` holds layout/format only — its colors come from btheme).

## Relationship to nix-colors

[nix-colors](https://github.com/misterio77/nix-colors) offers the same idea
at a larger scale: a catalog of base16 schemes plus a home-manager module
(`config.colorScheme`). We deliberately use a local `palettes.nix` instead
because:

- Omarchy's palette keys are semantic (`accent`, `muted`, `selection`), while
  base16 is a fixed 16-slot model — porting the white theme verbatim is
  easier with our keys.
- No new flake input or catalog dependency.
- The generated configs read `config.theme.palette` (or `config.colorScheme`
  in the future), so migrating to nix-colors later only requires changing
  where the palette comes from, not the consumers.

To migrate: set `themes.palette` (or a `colorScheme` option) to a
`nix-colors.colorSchemes.<name>` and keep the consumer modules reading the
same keys.
