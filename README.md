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
sudo nixos-rebuild switch --flake ~/Personal/dotfiles#dotfiles
```

## Notes

- `bnixos` still currently ships a monolithic personal config; once it exports a clean `nixosModules.system`, this flake stays the same shape and just gets thinner `personal.nix`.
- Keep secrets here (sops/agenix), never in public `bnixos`.
