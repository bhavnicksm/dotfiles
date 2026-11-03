{
  description = "Personal NixOS consumer of bnixos";

  inputs = {
    # Private repo: fetch over SSH so flakes can authenticate. Follows the
    # default branch (main); feature branches get an explicit ?ref= during
    # development and drop it once merged.
    bnixos.url = "git+ssh://git@github.com/bhavnicksm/bnixos.git?ref=main";
    nixpkgs.follows = "bnixos/nixpkgs";
    nixos-hardware.follows = "bnixos/nixos-hardware";
    home-manager.follows = "bnixos/home-manager";

    # Secret provisioning (sops)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixos-26.05 froze code-cursor at 3.5.17; Cursor is taken from this
    # input in home.nix. opencode now comes from bnixos (upstream 2.0).
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Hyprland 0.57.0 (nixos-unstable, 2026-11-01) only: NixOS/HM stay on
    # 26.05. personal.nix overlays just `hyprland` from this input; do not
    # add `inputs.nixpkgs.follows` — the compositor must keep its own
    # unstable dependency closure.
    hyprland-nixpkgs.url = "github:nixos/nixpkgs/0bb2eedc20e4739f29e8045034f2828ad7054f8f";

    # Grok Bot is an unfree .deb. The flake repackages it and already allows
    # unfree in its package output. Follow unstable, which is what it tests.
    grok-bot = {
      url = "github:jordangarrison/grok-bot-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, bnixos, nixpkgs, nixos-hardware, home-manager, sops-nix, ... }@inputs: {
    nixosConfigurations.dotfiles = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # Product: the bnixos system configuration
        bnixos.nixosModules.default

        # Device layer
        nixos-hardware.nixosModules.framework-amd-ai-300-series
        ./hardware-configuration.nix

        # Personal overlays: secrets, hostname, home-manager, extras
        ./personal.nix
      ];
    };
  };
}