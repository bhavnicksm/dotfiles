# AGENTS.md

Notes for agents working in this repository. See `docs/` for topic guides.

## What this repo is

A NixOS **flaky configuration** (`nixosConfiguration "dotfiles"`) that consumes
the private `bnixos` product flake over SSH and layers personal config on top:

- `flake.nix` — inputs (`bnixos` via `git+ssh`, `nixpkgs`/`home-manager`
  follow it, `sops-nix`), the single system config.
- `personal.nix` — machine identity (hostname `bnixos`, TZ, user
  `bhavnick`), SDDM theme, and the **home-manager wiring**
  (`home-manager.users.bhavnick = import ./home.nix`).
- `home.nix` — user config: shell, hyprland (keybinds, waybar), packages,
  themes, secrets, and the `home.file` block that installs `bin/` scripts.
- `config.nix` — static, theme-independent dotfiles under `config/`.
- `themes/` — palette catalog `palettes.nix`, the `themes.theme` option
  (theme-module.nix), and `templates/*.tpl` rendered at build time.
- `bin/` — helper scripts installed to `~/.local/bin` by `home.nix`.
- `docs/` — notes explaining the design decisions.

## Build / switch

```sh
sudo nixos-rebuild switch --flake ~/dotfiles#dotfiles
```

### Gotcha: the flake source only ships git-tracked files

When a flake lives in a git repo, Nix copies **git-tracked** files to the store
(working-tree content for modified tracked files; **untracked files are
excluded**). If `home.nix` references a new script that was never `git add`ed,
the build fails with:

```
error: path '/nix/store/...-source/bin/bt-device.sh' does not exist
```

Fix: `git add <new files>` (staging is enough; no commit needed) and rebuild.

### Gotcha: a pre-existing plain file at the managed target

If `~/.local/bin/<script>` already exists as a **regular file** (an old
hand-installed copy, not a store symlink), home-manager refuses to manage it and
`home-manager-bhavnick.service` fails activation with `Existing file ... is in
the way`. Fix: move the file aside (`mv ~/.local/bin/bt-menu.sh{,.old-bak}`),
then re-run the generation's `activate` (or `nixos-rebuild switch`).

## Theme model

- One line in `home.nix`: `themes.theme = "white";` — an enum over the keys of
  `themes/palettes.nix` (themselves Omarchy-style semantic palettes).
- `themes/theme-module.nix` renders every consumer (hyprland borders, ghostty,
  waybar css, wofi css, btop) from the selected palette via `templates/*.tpl`.
- `bin/theme-selector.sh` switches it: edits that line, then rebuilds.
- See `docs/theming.md`.

## Neovim

HM 26.05 owns `~/.config/nvim/init.lua` through `programs.neovim.initLua`
(plugin packpath boilerplate is prepended automatically) — do not hand-write
that file; declare config in `home.nix`. The old hand-written copy is at
`~/.config/nvim/init.lua.old-bak` until you're satisfied and delete it.

## Script conventions (`bin/`)

Installed via `home.nix`:

```nix
home.file.".local/bin/bt-device.sh".source = ./bin/bt-device.sh;
home.file.".local/bin/bt-device.sh".executable = true;
```

- **Single-purpose commands** (`bt-power.sh`, `bt-device.sh`, `bt-scan.sh`):
  explicit args, hard validation (MAC regex), answer with exit codes, no UI.
- **Thin menus** (`bt-menu.sh`, `launcher.sh`): own fuzzel/wofi + notify-send,
  dispatch to the single-purpose commands; resolve siblings via `SCRIPT_DIR`,
  never PATH assumptions.
- **Exit-code menu contract**: a dismissed top-level menu must end the script
  (`while main_menu; do :; done`, `main_menu` returns non-zero on dismiss —
  the old `while :; do main_menu; done` locked the menu open). Submenus return 0
  on dismissal to pop back up.
- Strict mode (`set -euo pipefail`; menus use `set -u` so a cancelled fuzzel
  prompt is not fatal). Shebang `#!/usr/bin/env bash` (deviation from Omarchy's
  `#!/bin/bash` for NixOS PATH portability) — see `docs/launchers-and-scripts.md`.
- Every `bluetoothctl` call wrapped in `timeout`. Bluetooth power is
  rfkill-aware and probes all controllers, modeled on Omarchy.
- The Bluetooth stack: `hardware.bluetooth.enable` + `powerOnBoot` in
  `personal.nix` (kernel + bluetoothd), `bluez` in `home.packages` so
  `bluetoothctl` is on PATH. `rfkill` works as the user — `/dev/rfkill` has
  a uaccess ACL.

## Hyprland config (Lua)

- `wayland.windowManager.hyprland.configType = "lua"` (26.05 default) writes
  `~/.config/hypr/hyprland.lua`, not `hyprland.conf`. The `settings` block in
  `home.nix` uses the 26.05 Lua generator (`_var`, `_args`, `mkLuaInline`).
  See `docs/hyprland-lua.md` for the full mapping and the DSL reference.
- **REVISIT:** the `togglesplit` bind (`$mod + J`) maps to
  `hl.dsp.layout("togglesplit")` best-effort; Hyprland 0.55 has no
  `window.split` dispatcher. Verify it dispatches; if not, drop/remap it.
- Starting point for this migration was the `pre-lua-migration` branch
  (last known-good hyprlang config at `576eaa9`).

## Keybindings (home.nix hyprland bind)

- `$mod SPACE` → `~/.local/bin/launcher.sh`
- `$mod B` → `~/.local/bin/bt-menu.sh`
- Waybar launcher button → same `launcher.sh`

## Verification

```sh
bash -n bin/*.sh
nix shell nixpkgs#shellcheck -c shellcheck bin/*.sh
nix-instantiate --parse home.nix     # syntax check without flake eval
~/.local/bin/bt-power.sh is-on; echo $?   # exit-contract smoke test
```
Hyprland Lua config can be validated **without a running compositor** using the
mock `hl` API mirroring the real stubs:
```sh
nix build .#nixosConfigurations.dotfiles.config.system.build.toplevel --no-link
LUA=$(nix-build '<nixpkgs>' -A lua 2>/dev/null || true)
# or use the store lua, then:
lua bin/hl-mock.lua "<path-to-generated-hyprland.lua>"
```
`bin/hl-mock.lua` fails with `attempt to index/call a nil value (field '<name>')`
for any unknown top-level/`hl.dsp.*` name — catching the same errors Hyprland
raises, before you boot into a bad config.

Full `nix flake check`/eval needs the private SSH `bnixos` input and network.

## Secrets

sops-nix (`defaultSopsFile ./secrets.yaml`, age key at
`~/.config/sops/age/keys.txt`). `OPENROUTER_API_KEY` is the only secret and is
loaded into `home.sessionVariables`. See `docs/sops-session-vars.md`.

## Nix style

Two-space indent, double-quoted attrs, one option per line; follow the
`themes.theme`/`home.file` patterns above rather than inventing new ones.