{ config, lib, pkgs, inputs, ... }:

{
  # Machine identity + anything that is *you*, not the product.
  networking.hostName = "bnixos";

  # NixOS-level zsh support (PATH for the login shell)
  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bhavnick = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  # Home-manager: personal configuration, packages, and services
  imports = [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.bhavnick = import ./home.nix;
        extraSpecialArgs = { inherit inputs; };
      };
    }
  ];
}