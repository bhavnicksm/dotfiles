# Hyprland: hyprlang (`.conf`) -> Lua migration

Since Hyprland 0.55, `hyprlang` (the `.conf` format) is deprecated in favour of
`~/.config/hypr/hyprland.lua`. Home-manager 26.05 defaults
`wayland.windowManager.hyprland.configType` to `"lua"`.

This repo originally pinned `configType = "hyprlang"` (commit `576eaa9`) to stay
working on Hyprland 0.55.4. `home.nix` now uses `configType = "lua"`.

## How the settings map (26.05 generator)

With `configType = "lua"` each `settings` attribute becomes an `hl.<name>(…)`
call in `hyprland.lua`:

- nested attrset of scalar/color values -> `hl.general({ … })` etc.
- `_var` -> a Lua local: `mod._var = "SUPER"` -> `local mod = "SUPER"`
- `_args` list -> the arguments to the `hl.<name>` call
- `lib.generators.mkLuaInline` -> raw Lua (each is wrapped in `( )` by `toLua`,
  which is valid)
- `on._args = [ "hyprland.start" (function) ]` -> the autostart hook
- `bind` list of `{ _args = [ key dispatcher opts ] }` -> repeated `hl.bind` calls
- dotted keys like `general."col.active_border"` render as
  `["col.active_border"]` (valid Lua)

`home.nix` defines small helpers (`m`, `ms`, `exec`, `focus`, `swap`, `ws`,
`movews`) over `mkLuaInline` to spell the common bind shapes.

## Bind / dispatcher reference (verified vs Hyprland 0.55.4 stubs/docs)

| hyprlang | Lua |
|---|---|
| `$mod` | `local mod = "SUPER"` (via `mod._var`) |
| `exec, cmd` | `hl.dsp.exec_cmd("cmd")` |
| `killactive,` | `hl.dsp.window.close()` |
| `exit,` | `hl.dsp.exit()` |
| `togglefloating,` | `hl.dsp.window.float({ action = "toggle" })` |
| `pseudo,` | `hl.dsp.window.pseudo({ action = "toggle" })` |
| `movefocus, l/r/u/d` | `hl.dsp.focus({ direction = "l" })` |
| `swapwindow, l/r/u/d` | `hl.dsp.window.swap({ direction = "l" })` |
| `workspace, N` / `e+1` / `e-1` | `hl.dsp.focus({ workspace = "N" })` / `({ workspace = "e+1" })` |
| `movetoworkspace, N` | `hl.dsp.window.move({ workspace = "N", follow = true })` |
| `bindl` (media keys) | `hl.bind("XF86…", … , { locked = true })` |

Color arguments (e.g. `general.col.active_border`) are Lua **`"rgba(r,g,b,a)"`**
strings — the old comma-less `rgb(XXXXXX)` hyprlang form is invalid in Lua.
`themes/theme-module.nix` uses `hexToRgba` for these.

## Autostart

Desktop daemons (waybar, dunst, hyprpaper) are **`systemd.user.services`** in
`home.nix` — `PartOf`/`WantedBy = graphical-session.target`,
`After = hyprland-session.target`, `Restart = on-failure` — not inline Lua. The
`hl.on("hyprland.start", …)` hook only runs one-shot setup commands
(`hyprctl setcursor`, gnome-keyring).

## hyprpaper

hyprpaper **>= 0.8** (hyprtoolkit rewrite) broke the config format: `preload`
no longer exists and `wallpaper = monitor,path` one-liners are gone. Wallpapers
are anonymous blocks, config in `themes/templates/hyprpaper.conf.tpl`:

```ini
wallpaper {
    monitor =        # empty = fallback for all monitors
    path = <store path>
    fit_mode = cover
}
splash = false
```

## Caveats / things to REVISIT

- **togglesplit**: Hyprland's Lua `hl.dsp.window` has no `split`/`togglesplit`
  dispatcher on 0.55. It is currently bound best-effort to
  `hl.dsp.layout("togglesplit")` (dwindle layout message) and needs a runtime
  check — if it doesn't dispatch, drop or remap the `mod + J` bind.
- Border colors rely on Hyprland accepting `rgba(r,g,b,a)` strings for
  `col.active_border`; verify borders render at runtime.

## Local validation (no running compositor)

`bin/hl-mock.lua` mirrors Hyprland's Lua `hl` API (from
`share/hypr/stubs/hl.meta.lua`) and loads the generated `hyprland.lua` against
it. Unknown top-level/`hl.dsp.*` names raise the same `attempt to call a nil
value` error Hyprland would. Example:

```sh
nix build .#nixosConfigurations.dotfiles.config.system.build.toplevel --no-link
lua bin/hl-mock.lua <store-path>/hm_hypr_hyprland.lua
```

## Verification / non-bricking rollout

```sh
nix-instantiate --parse home.nix            # syntax check (per AGENTS.md)
nixos-rebuild build --flake ~/Projects/dotfiles#dotfiles   # builds, no activation
# inspect the generated hyprland.lua from the new system closure, e.g.
#   ls "$(nix path-info ~/Projects/dotfiles#nixosConfigurations.dotfiles.config.system.build.toplevel)/etc/profiles/per-user/bhavnick/etc/xdg/hypr"
nixos-rebuild boot --flake ~/Projects/dotfiles#dotfiles   # stage; reboot to apply
```

The previous generation stays in GRUB, so if the Lua config fails to load, boot
the older entry and `nixos-rebuild switch` back. The last known-good hyprlang
state is also preserved on the `pre-lua-migration` branch.