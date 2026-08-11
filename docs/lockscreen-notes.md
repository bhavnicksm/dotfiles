# Lockscreen notes

Current setup + what to do when a lock experiment goes wrong.

## Current state

- **Tool:** `hyprlock` (package at `home.nix`, bind `$mod, L → exec, hyprlock`
  at `home.nix:143`).
- Auth is PAM-backed (`hyprlock` ships `home-path/etc/pam.d/hyprlock`).
- Idle/sleep handling is `hypridle` (also in `home.packages`).
- **Login screen:** SDDM with the custom `omarchy-white` theme (built from
  `themes/sddm/main.qml.tpl` into `share/sddm/themes/omarchy-white`, wired in
  `personal.nix` via `services.displayManager.sddm.theme = lib.mkForce
  "omarchy-white"`). Overrides bnixos's `catppuccin-mocha`.
- **Login keyring unlock:** `security.pam.services.sddm.enableGnomeKeyring`
  (bnixos) + `gnome-keyring-daemon --components=secrets` in the Hyprland
  `exec-once`.

## SDDM theme experiment (2026-08-10)

Status: **installed and built, NOT yet eyeballed** (requires logout to see).

What changed:
- `personal.nix`: builds `sddmTheme` + forces `sddm.theme` to `omarchy-white`.
- Theme generator: `themes/sddm/main.qml.tpl` (mirrors the hyprlock look:
  golden-gate wallpaper, dim overlay, rounded frosted card). Rendered from the
  active palette at build time.
- `fonts.packages` now includes `nerd-fonts.jetbrains-mono` so the greeter
  (runs as root) sees the font.

To revert this experiment specifically (back to catppuccin-mocha without a
full rollback):
1. Remove the two lines in `personal.nix`:
   - `services.displayManager.sddm.theme = lib.mkForce "omarchy-white";`
   - `environment.systemPackages = [ sddmTheme ];`
2. `sudo nixos-rebuild switch --flake ~/Projects/dotfiles#dotfiles`

Debug note (2026-08-10): first switch showed a "plain blue" greeter. Cause:
`metadata.desktop` must use SDDM's `[SddmGreeterTheme]` format
(`Type=sddm-theme`, `Theme-Id=`, `MainScript=`, `QtVersion=6`), not
`[Desktop Entry]` — otherwise the greeter logs
`The theme requires missing .../bin/sddm-greeter . Using fallback theme`
and falls back to maldives (blue). Diagnose with
`journalctl -u display-manager -b | grep -i "fallback theme"`.

To get to a known-good login screen quickly, regardless of what broke:
```sh
# on a TTY (Ctrl+Alt+F2) or from an SSH session:
sudo nixos-rebuild switch --flake ~/Projects/dotfiles --rollback
```
This switches back to the previous system generation (catppuccin-mocha SDDM).
`nixos-rebuild list-generations` shows what `--rollback` will pick.

## Archaeology: have we ever used anything else?

Checked 2026-08-10:

- **Home-manager generations 1–51** (`~/.local/state/nix/profiles/home-manager-*-link`):
  every generation with a hypr config (17–51) binds `$mod, L → hyprlock`.
  The only lock binary ever installed in any generation is `hyprlock`.
- **NixOS system generations 1–44**: no lock packages/binds at system level.
- **Git history** (dotfiles `main` + `nixos` branches, `bnixos`): nothing,
  only nvim's `lazy-lock.json`.

Conclusion: no `swaylock`/`waylock`/`gtklock`/`i3lock`/`physlock` was ever
recorded on this machine. Traces of past "force revert" experiments are lost —
edits to `~/.config/hypr/hyprland.conf` are invisible because it's a symlink
into the store generation, and any experiment not committed is unrecoverable.

## If a future lock experiment locks you out

1. **Switch to a TTY:** `Ctrl+Alt+F2` (or `chvt 2`). The lock only covers the
   Hyprland session; the TTY login always works. From there you can edit files
   and rebuild without a GUI.
2. **Disable the bind quickly:** edit `~/.config/hypr/hyprland.conf`, remove
   the `$mod, L` / idle lock line, then `hyprctl dispatch exec hyprlandctl...`
   or simply reload with `hyprctl reload` (or restart the session).
3. **Roll back to the last good build:**
   ```sh
   sudo nixos-rebuild switch --flake ~/Projects/dotfiles --rollback
   # home-manager side:
   nix-env --switch-generation gen --profile ~/.local/state/nix/profiles/home-manager
   ```
4. Confirm the current/rollback target with `nixos-rebuild list-generations`
   and `home-manager generations`.

Prefer committing lock experiments (`home.nix`) over editing the generated
`hyprland.conf` — that way `git log` is the work log.