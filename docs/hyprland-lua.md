# Hyprland: hyprlang (`.conf`) -> Lua migration

Since Hyprland 0.55, `hyprlang` (the `.conf` format) is deprecated in favour of
`~/.config/hypr/hyprland.lua`. Home-manager 26.05 defaults
`wayland.windowManager.hyprland.configType` to `"lua"`.

This repo originally pinned `configType = "hyprlang"` (commit `576eaa9`) to stay
working on Hyprland 0.55.4. `home.nix` now uses `configType = "lua"`.

## Targeted Hyprland 0.57.0 pin (26.05 base)

NixOS and home-manager stay on 26.05; **only the compositor** comes from
nixpkgs-unstable. `flake.nix` carries a dedicated input:

```nix
hyprland-nixpkgs.url = "github:nixos/nixpkgs/0bb2eedc20e4739f29e8045034f2828ad7054f8f";
```

That rev is nixos-unstable 2026-11-01 and contains Hyprland **0.57.0**
(`nix eval` the input's `legacyPackages.x86_64-linux.hyprland.version` to
confirm). `personal.nix` overlays exactly one attribute:

```nix
nixpkgs.overlays = [
  (final: prev: {
    hyprland = inputs.hyprland-nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.hyprland;
  })
];
```

Why this shape:

- The NixOS `programs.hyprland.package` and the HM
  `wayland.windowManager.hyprland.package` both default to `pkgs.hyprland`.
  HM runs with `useGlobalPkgs = true`, so one overlay reaches both modules,
  the `security.wrappers.Hyprland` wrapper, the session package, and HM's
  `finalPackage` (HM re-overrides it with `enableXWayland`, which 0.57 still
  accepts).
- **No `inputs.nixpkgs.follows`.** The compositor keeps the unstable
  dependency closure it was built against (`aquamarine`, `hyprutils`,
  `hyprlang`, `hyprcursor`, …). Following 26.05 would mix library ABIs and
  can fail at build or load time.
- Only `hyprland` is replaced. `hyprpaper`, `hyprlock`, `hypridle`,
  `hyprsunset`, `hyprpicker`, … remain the 26.05 packages.
- The **portal stays on 26.05** (`xdg-desktop-portal-hyprland` 1.3.12). HM
  26.05 computes `finalPortalPackage = portalPackage.override { hyprland =
  finalPackage; }`, but unstable's portal 1.5.0 dropped the `hyprland`
  argument — overlaying it would break evaluation. 1.3.12 only puts
  `hyprland` on `hyprland-share-picker`'s `PATH` (no compile-time coupling),
  so it builds against 0.57.0, but the **1.3.12 ↔ 0.57.0 runtime combination
  is untested**; treat portal screensharing as unverified until a session
  test.

### Rendering / Mesa caveat

The system graphics driver stays on stable 26.05's **Mesa 26.1.5**, while the
0.57.0 compositor closure brings its own **`mesa-libgbm` 26.1.3**. The new
binary's loader probes pass (it runs `--version` and `--verify-config`), but
rendering, performance, and GPU-specific behavior need a **live session test**.
Do not preemptively overlay Mesa; only revisit if a live session shows a
driver/GBM problem.

The separate `nixpkgs-unstable` input (Cursor/grok-bot) still contains
Hyprland 0.56.2 and is deliberately **not** updated or reused for this: do
not "bump unstable" to get Hyprland, or Cursor/grok-bot move with it.

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
bnixos `flakes/btheme` uses `hexToRgba` for these (colors now rendered upstream).

## Autostart

Desktop daemons (bbar, dunst, hyprpaper) are **`systemd.user.services`** in
`home.nix` — `PartOf`/`WantedBy = hyprland-session.target` (started by
Hyprland's own activation hook after the Wayland env is set), `Restart =
on-failure` — not inline Lua. There is no `hl.on("hyprland.start", …)` hook
anymore: gnome-keyring runs via `services.gnome-keyring` and the cursor theme
via `home.sessionVariables` (`HYPRCURSOR_*`/`XCURSOR_*`). The status bar is
**bbar** (bnixos `flakes/bbar`, a Quickshell bar), which ships its own
`systemd.user.services.bbar`; waybar is removed.

⚠ Do not add `After = hyprland-session.target` / `After =
graphical-session.target` to these services: combined with the WantedBy it
creates a systemd ordering cycle that deletes every start job (daemons never
launch).

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

- **togglesplit**: Hyprland 0.57's Lua `hl.dsp.window` still has no
  `split`/`togglesplit` dispatcher (checked against the 0.57.0 stubs). It is
  bound best-effort to `hl.dsp.layout("togglesplit")` (dwindle layout
  message) and needs a runtime check — if it doesn't dispatch, drop or remap
  the `mod + J` bind.
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

## Pre-activation checks (0.57 pin)

Nothing below activates the system or starts a compositor.

```sh
cd ~/Projects/dotfiles
nix-instantiate --parse personal.nix
nix eval --raw .#nixosConfigurations.dotfiles.config.programs.hyprland.package.version
#   -> 0.57.0   (system: NixOS programs.hyprland)
nix eval --raw \
  .#nixosConfigurations.dotfiles.config.home-manager.users.bhavnick.wayland.windowManager.hyprland.finalPackage.version
#   -> 0.57.0   (HM, after useGlobalPkgs + enableXWayland override)
nix eval --raw .#nixosConfigurations.dotfiles.config.boot.kernelPackages.kernel.version
#   -> 7.1.7    (unchanged baseline)
nix build .#nixosConfigurations.dotfiles.config.system.build.toplevel \
  --no-link --print-out-paths --show-trace
```

Then syntax-check and load-test the **generated** Lua from the new closure,
and ask the new binary to parse it (no compositor is started):

```sh
TOP=$(nix build .#nixosConfigurations.dotfiles.config.system.build.toplevel --no-link --print-out-paths | tail -1)
LUA=$(nix-store -qR "$TOP" | grep 'hm_hypr.*hyprland\.lua' | head -1)
# Resolve the NEW closure's binary explicitly: a bare `Hyprland` on PATH is
# still the running 0.55.4 session's package and proves nothing.
HYPR=$(readlink -f "$TOP/sw/bin/Hyprland")
"$HYPR" --version          # expect 0.57.0
nix shell --inputs-from . nixpkgs#lua5_5 -c luac -p "$LUA"
nix shell --inputs-from . nixpkgs#lua5_5 -c lua bin/hl-mock.lua "$LUA"
"$HYPR" --verify-config -c "$LUA"
```

`--verify-config` is listed in `Hyprland --help` on 0.57.0: it parses the
config and exits without running, so it is the **authoritative** load
compatibility check. `bin/hl-mock.lua` still mirrors the 0.55 stubs and is
**not exhaustive**: 0.57 removed at least `debug.fifo_pending_workaround` and
renamed some layer fields, so the mock only proves that the API names/config
keys **used here** still resolve. Do not infer broader 0.57 compatibility
from it.

## Trial and rollback (test is not a rollback point)

`nixos-rebuild test` activates the new system in `/run/current-system` for the
current boot, but it does **not** create/update the system profile generation
or a boot entry. Do not treat it as a rollback point. Record the old closure
first:

```sh
OLD=$(readlink -f /run/current-system); echo "$OLD"
```

- **Smoke trial without touching boot:** `sudo nixos-rebuild test --flake
  ~/dotfiles#dotfiles`, then log out/in (or restart the session) to exercise
  Hyprland 0.57. If the session fails to start, switch to a TTY
  (Ctrl+Alt+F2) and restore the recorded closure with
  `sudo "$OLD/bin/switch-to-configuration" test`, then start a session
  normally. `switch-to-configuration test` runs the activation script **and**
  coordinates the systemd unit restart/reload set. `"$OLD/activate"` alone
  does re-point `/run/current-system`, but it does not restart/reload units,
  so use the `switch-to-configuration` entry point for a clean rollback.
- **Persistent trial:** `sudo nixos-rebuild boot --flake
  ~/dotfiles#dotfiles` adds a generation and the boot entry. Reboot; if the
  session is broken, pick the **previous boot generation** in the boot menu
  (GRUB/systemd-boot keep it). `sudo nixos-rebuild switch --rollback` also
  re-activates the previous profile from a working session/TTY.
- **Code rollback:** `git revert <upgrade commit>` (or check out the last
  known-good flake rev). Do **not** `git restore`/`git reset` a dirty tree —
  that discards unrelated local work. The last known-good hyprlang state is
  also preserved on the `pre-lua-migration` branch.

There is no destructive cleanup needed: the old system generations and their
store paths stay until a GC, so both `"$OLD/bin/switch-to-configuration" test`
and booting the previous entry work after the upgrade.