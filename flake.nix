{
  description = "Personal NixOS consumer of bnixos";

  inputs = {
    # Private repo: fetch over SSH so flakes can authenticate
    bnixos.url = "git+ssh://git@github.com/bhavnicksm/bnixos.git";
    nixpkgs.follows = "bnixos/nixpkgs";
    nixos-hardware.follows = "bnixos/nixos-hardware";
    home-manager.follows = "bnixos/home-manager";

    # Secret provisioning (sops)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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