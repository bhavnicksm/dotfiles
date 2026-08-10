# dotfiles

Personal NixOS config. Consumes [`bnixos`](https://github.com/bhavnicksm/bnixos) as a product flake input — this repo is the dogfood machine, not the product.

## Layout

```
flake.nix                 # wires bnixos + hardware + personal
hardware-configuration.nix
personal.nix              # hostname, secrets, home-manager, extras
```

## Branch

`nixos` — rework away from the old Stow/neovim/zsh layout toward the bnixos consumer model.

## Rebuild (on the laptop)

```bash
sudo nixos-rebuild switch --flake ~/Projects/dotfiles#dotfiles
```

## Notes

- `bnixos` is the product (system config, no personal bits). This repo holds the personal layer: hostname, user, home-manager.
- Keep secrets here (sops/agenix), never in public `bnixos`.
