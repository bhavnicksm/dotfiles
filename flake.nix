{
  description = "Personal NixOS consumer of bnixos";

  inputs = {
    bnixos.url = "github:bhavnicksm/bnixos";
    nixpkgs.follows = "bnixos/nixpkgs";
    nixos-hardware.follows = "bnixos/nixos-hardware";
    home-manager.follows = "bnixos/home-manager";
  };

  outputs = { bnixos, nixpkgs, nixos-hardware, home-manager, ... }: {
    nixosConfigurations.dotfiles = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Product (once bnixos exposes nixosModules.system cleanly)
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
