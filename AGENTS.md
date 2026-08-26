# AGENTS.md

Notes for agents working in this repository. See `docs/` for topic guides.

## What this repo is

A NixOS **flaky configuration** (`nixosConfiguration "dotfiles"`) that consumes
the private `bnixos` product flake over SSH and layers personal config on top:

- `flake.nix` — inputs (`bnixos` via `git+ssh`, `nixpkgs`/`home-manager`
  follow it, `sops-nix`), the single system config.
- `personal.nix` — machine identity (hostname `bnixos`, TZ, user
  `bhavnick`), SDDM theme, unfree app allowance, and the **home-manager
  wiring** (`home-manager.users.bhavnick = import ./home.nix`).
- `home.nix` — user config: theme selection (`btheme.name` + catalog),
  personal zsh aliases, sops secrets, keybind overrides, hyprpaper unit,
  and the b*/bshell/bnight enables. The default desktop (look, shell,
  CLI tools, ghostty defaults) ships upstream now.
- `config.nix` — static, theme-independent dotfiles under `config/`.
- `themes/` — palette catalog `palettes.nix` (+ per-theme `starship`/
  `wallpaper` extras) and the SDDM greeter template. The theming engine
  itself is upstream: bnixos `flakes/btheme`.
- `bin/` — dev-only helpers (`hl-mock.lua`); the user-facing scripts moved
  upstream to bnixos `flakes/bblue` (installed by the `bblue` HM module).
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
error: path '/nix/store/...-source/bin/some-new-script.sh' does not exist
```

Fix: `git add <new files>` (staging is enough; no commit needed) and rebuild.

### Gotcha: a pre-existing plain file at the managed target

If `~/.local/bin/<script>` already exists as a **regular file** (an old
hand-installed copy, not a store symlink), home-manager refuses to manage it and
`home-manager-bhavnick.service` fails activation with `Existing file ... is in
the way`. Fix: move the file aside (`mv ~/.local/bin/bt-menu.sh{,.old-bak}`),
then re-run the generation's `activate` (or `nixos-rebuild switch`).

## Which packages live where (bnixos core vs dotfiles)

The **default desktop ships with bnixos**, not here: `bnixos.packages.core`
(bnixos `packages.nix`) installs the whole stack — shell + Hyprland stack
(dunst, hyprpaper, hyprlock, hypridle, hyprpicker, grim, slurp,
cliphist, wl-clipboard, btop, bluez, wifitui), secrets (libsecret,
gnome-keyring, age, sops), the JetBrains Mono font, and the browser via
`bnixos.packages.browser`. There is no fuzzel/wofi — app search and dmenu
prompts come from the **blaunch** Quickshell launcher (`inputs.bnixos.homeModules.blaunch`).

- `home.nix` `home.packages` holds only **personal extras not in core**
  (spotify, code-cursor-fhs, pywal, nil, python312, uv).
- The browser is bnixos's default (Google Chrome) via
  `bnixos.packages.core` — no firefox. Override it only by setting
  `bnixos.packages.browser` in `personal.nix`. Unfree allowances: the
  product allows its default browser; personal unfree apps go in
  `bnixos.packages.allowUnfree` (personal.nix) — never override the
  predicate wholesale.
- The shell experience (zsh/starship/fzf/eza/zoxide/yazi/bat/ripgrep/
  lazygit + ghostty static defaults + generic aliases) is upstream too:
  `bnixos.homeModules.bshell`, enabled in home.nix. Its tools ship in
  `bnixos.packages.core`. Personal aliases (`nrb`, `sec`, `ncl`) merge over
  bshell's set via `programs.zsh.shellAliases` here (bshell provides
  e.g. `wt` → wifitui).
- Night light is `bnixos.homeModules.bnight` (hyprsunset unit + schedule).
- To change what ships by default, edit bnixos `packages.nix`, NOT
  `home.nix`. To add a machine-only package, add it to `home.packages`.

## Theme model

- One line in `home.nix`: `btheme.name = "white";` — a key of the
  consumer-owned catalog `themes/palettes.nix`, fed to upstream via
  `btheme.themes` (wallpapers resolved to store paths in home.nix).
- bnixos `flakes/btheme` owns the renderer: ghostty, btop, hyprlock,
  hyprpaper, opencode, gtk, starship colors, hyprland borders, and the
  Hyprland desktop look defaults (gaps/rounding/shadows/animations/splash —
  mkDefault'd, override declaratively from home.nix).
- Themed components (bbar/blaunch/bnotif/bnixvim) read
  `config.btheme.palette`; they have no palette options anymore.
- Switching themes is declarative: edit the `btheme.name = "…";` line in
  `home.nix` and rebuild.
- See `docs/theming.md`.

## Neovim

HM 26.05 owns `~/.config/nvim/init.lua` through `programs.neovim.initLua`
(plugin packpath boilerplate is prepended automatically) — do not hand-write
that file; declare config in `home.nix`. The old hand-written copy is at
`~/.config/nvim/init.lua.old-bak` until you're satisfied and delete it.

## Script conventions (bnixos `flakes/bblue`)

The bluetooth scripts live upstream now (`bnixos flakes/bblue/bin/`, installed
to `~/.local/bin` by the `bblue` module — same paths as when they lived here):

- **Single-purpose commands** (`bt-power.sh`, `bt-device.sh`, `bt-scan.sh`):
  explicit args, hard validation (MAC regex), answer with exit codes, no UI.
- **Thin menus** (`bt-menu.sh`): own `bl-select` (blaunch's dmenu mode) +
  notify-send, dispatch to the single-purpose commands; resolve siblings via
  `SCRIPT_DIR`, never PATH assumptions.
- **Exit-code menu contract**: a dismissed top-level menu must end the script
  (`while main_menu; do :; done`, `main_menu` returns non-zero on dismiss —
  the old `while :; do main_menu; done` locked the menu open). Submenus return 0
  on dismissal to pop back up.
- Strict mode (`set -euo pipefail`; menus use `set -u` so a cancelled `bl-select`
  prompt is not fatal). Shebang `#!/usr/bin/env bash` (deviation from Omarchy's
  `#!/bin/bash` for NixOS PATH portability) — see `docs/launchers-and-scripts.md`.
- Every `bluetoothctl` call wrapped in `timeout`. Bluetooth power is
  rfkill-aware and probes all controllers, modeled on Omarchy.
- The Bluetooth stack: `hardware.bluetooth.enable` + `powerOnBoot` +
  `settings.General.Pairable` ship from bnixos `configuration.nix`; `bblue`
  installs the scripts, `bluez-tools` (bt-agent), a persistent
  `bt-agent -c NoInputNoOutput` user service, and bluetui. Discovery is held
  by one long-lived `bluetoothctl` client per scan window (BlueZ cancels
  discovery when the requesting client exits). `rfkill` works as the user —
  `/dev/rfkill` has a uaccess ACL.

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

- `$mod SPACE` → `bl-launch` (toggles the blaunch app menu; on PATH via
  `inputs.bnixos.homeModules.blaunch`'s `home.packages`, not `~/.local/bin`)
- `$mod B` → bluetui in a floating ghostty (bbinds default `bluetooth` bind; class `bblue-tui`)
- `$mod I` → wifitui in a floating ghostty (bbinds default `wifi-tui` bind;
  class `bwifi-tui`, floated by windowrules bbinds ships itself; `wt`
  zsh alias from bshell, package in bnixos `packages.core`)
- Universal binds: `$mod T` → new tab and `$mod N` → new window live in
  home.nix `keybinds.override` (class-branching Lua rendered from the
  `windowCommands` data there; terminal classes come from bbinds'
  `keybinds.terminals`), plus `$mod SHIFT+N` → bnotif DND toggle (moved
  off `$mod N`; `$mod N` is a strict class→command map, unmapped classes
  no-op). Universal tab-close ships upstream as a bbinds default:
  `$mod W` (same `keybinds.terminals` branch); window close moved to
  `$mod Q`.
- DND indicator: bbar's `Dnd` widget (bnixos `flakes/bbar`) shows a bell-off
  glyph in the bar while DND is on (state watched from
  `~/.local/state/bnotif/dnd`), and left-click toggles DND via `b-ipc`.

## Verification

```sh
bash -n ~/Projects/bnixos/flakes/bblue/bin/*.sh
nix shell nixpkgs#shellcheck -c shellcheck ~/Projects/bnixos/flakes/bblue/bin/*.sh
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

## Workflow playbook (do these every time)

### Hyprland Lua change → validate before claiming it works

1. Edit `home.nix` hyprland `settings`.
2. `nix-instantiate --parse home.nix` (syntax).
3. Rebuild + grab the generated lua:
   ```sh
   TOP=$(nix build .#nixosConfigurations.dotfiles.config.system.build.toplevel --no-link --print-out-paths | tail -1)
   LUA=$(nix-store -qR "$TOP" | grep 'hm_hypr.*hyprland.lua' | head -1)
   ```
4. Validate (catches `attempt to call nil value` and bad syntax):
   ```sh
   lua bin/hl-mock.lua "$LUA"          # API names vs real stubs
   luac -p "$LUA"                       # Lua syntax
   ```
5. The plain-config sections must be under `config = { … }` → `hl.config({ … })`.
   There is **no** `hl.general` / `hl.decoration` / `hl.animations` function.
   There is **no top-level `hl.focus`** — workspace switch is
   `hl.dsp.focus({ workspace = … })`.

### A package regressed on the 26.05 branch

Given 26.05 froze some tools at broken versions, for any suspect package:

1. Check versions across branches and what you're actually solving:
   ```sh
   nix eval --impure --raw --expr 'let p = (builtins.getFlake "github:nixos/nixpkgs/nixos-26.05").legacyPackages.x86_64-linux.<pkg>; in p.version'
   ```
2. If the branch version is broken, you can **pin a good one via overlay** (like
   `opencode` 1.18.13 from `nixpkgs-unstable` in `personal.nix`) — or **migrate
   config** to the new version's format (like `hyprpaper` 0.8) instead of
   pinning. Prefer migrating when it's just a config break.
3. To test a package from another branch live **before** touching the flake:
   ```sh
   nix build --impure --no-link --print-out-paths --expr \
     'let f = builtins.getFlake "github:nixos/nixpkgs/<branch>"; in f.legacyPackages.x86_64-linux.<pkg>'
   ```
   then run the resulting binary against the live session.
4. Overlay pattern (in `personal.nix`):
   ```nix
   nixpkgs.overlays = [ (final: prev: {
     <pkg> = inputs.<nixpkgs-branch>.legacyPackages.${pkgs.stdenv.hostPlatform.system}.<pkg>;
   }) ];
   ```
   New inputs go in `flake.nix`; run `nix flake lock` after adding one.

### Declarative autostart (systemd user services)

- Daemons (waybar, dunst, hyprpaper) are `systemd.user.services`, **not** Lua
  hooks: `PartOf = [ "hyprland-session.target" ]` + `WantedBy =
  "hyprland-session.target"`, `Restart = "on-failure"`.
- **Never add `After = hyprland-session.target`** — combined with the WantedBy
  it creates an ordering cycle and systemd deletes the start job (daemons
  silently never launch; watch for it in `journalctl --user -u <svc>`).
- Autostart one-shots are handled declaratively too: gnome-keyring is
  **system-owned** (bnixos `configuration.nix` →
  `services.gnome.gnome-keyring.enable`: PAM `auto_start` unlocks the login
  keyring at SDDM login via the `login` PAM service — the per-service
  `security.pam.services.sddm.enableGnomeKeyring` is silently ignored because
  the sddm module uses `useDefaultRules = false` — plus D-Bus activation via
  the `/run/wrappers` setcap wrapper), cursor theme via `home.sessionVariables`
  (`HYPRCURSOR_*`/`XCURSOR_*`) — no `hyprctl setcursor` exec needed.
- Cursor: `~/.config/Cursor/argv.json` (HM-managed) forces
  `"password-store": "gnome-libsecret"` — on Hyprland, Electron's os_crypt
  autodetection doesn't pick the keyring and Cursor shows "An OS keyring
  couldn't be identified".

### hyprpaper ≥ 0.8 (hyprtoolkit rewrite)

Config format broke: no `preload`, no `wallpaper = monitor,path` one-liner.
Use anonymous blocks (config template lives upstream in bnixos `flakes/btheme/templates/hyprpaper.conf.tpl`):
```ini
wallpaper {
    monitor =        # empty = fallback for all monitors
    path = <path>
    fit_mode = cover
}
splash = false
```
`~/.config/hypr/hyprpaper.conf` is HM-managed; the running daemon reads the
default path. A `-c <path>` run is how you test configs live.

### Live-system testing without a reboot

- systemd units: `systemctl --user disable --now <svc>`, copy corrected units
  into `~/.config/systemd/user/`, `daemon-reload`, `enable`, then `restart
  hyprland-session.target`. (`pgrep -x waybar` misses `.waybar-wrapped` — use
  `systemctl --user status` or `pgrep -f`.)
- Hyprland state: `hyprctl layers`, `hyprctl getoption <opt>`, `grim` +
  screenshot.

### Finishing

Before reporting done: `git status --short` clean, commit with a repo-style
message, `git push origin nixos`. Only bump `main` when asked.

## Secrets

sops-nix (`defaultSopsFile ./secrets.yaml`, age key at
`~/.config/sops/age/keys.txt`). `home.sessionVariables` maps over **all**
secrets (`builtins.mapAttrs`), exporting each as an env var named after it —
adding a secret to `secrets.yaml` exports it automatically. Env vars are
visible to all processes, so prefer file paths unless a secret must be in the
environment. See `docs/sops-session-vars.md`.

## Nix style

Two-space indent, double-quoted attrs, one option per line; follow the
`btheme.name`/`home.file` patterns above rather than inventing new ones.