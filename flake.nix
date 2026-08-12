{
  description = "Personal NixOS consumer of bnixos";

  inputs = {
    # Private repo: fetch over SSH so flakes can authenticate. Points at the
    # bbar/quickshell branch while the Quickshell bar replaces waybar; drop
    # the ?ref= once merged to bnixos main.
    bnixos.url = "git+ssh://git@github.com/bhavnicksm/bnixos.git?ref=bbar/quickshell";
    nixpkgs.follows = "bnixos/nixpkgs";
    nixos-hardware.follows = "bnixos/nixos-hardware";
    home-manager.follows = "bnixos/home-manager";

    # Secret provisioning (sops)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # opencode latest, for an overlay pin: the nixos-26.05 branch froze
    # opencode at 1.15.10 whose DB migration errors against the 1.18.x data
    # dir. Keep `opencode` on nixpkgs-unstable (1.18.13) via personal.nix.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
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