{
  description = "Personal NixOS consumer of bnixos";

  inputs = {
    # Private repo: fetch over SSH so flakes can authenticate. Follows the
    # default branch (main); feature branches get an explicit ?ref= during
    # development and drop it once merged. bmux (zellij) lives on
    # bmux/zellij until merged.
    bnixos.url = "git+ssh://git@github.com/bhavnicksm/bnixos.git?ref=bmux/zellij";
    nixpkgs.follows = "bnixos/nixpkgs";
    nixos-hardware.follows = "bnixos/nixos-hardware";
    home-manager.follows = "bnixos/home-manager";

    # Secret provisioning (sops)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixos-26.05 froze opencode at 1.15.10 (DB migration fails against the
    # 1.18.x data dir) and code-cursor at 3.5.17. opencode is overlaid in
    # personal.nix; Cursor is taken from this input in home.nix.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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