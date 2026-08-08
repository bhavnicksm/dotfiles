{ config, lib, pkgs, ... }:

{
  # Machine identity + anything that is *you*, not the product.
  networking.hostName = "bnixos";

  # Temporary: until bnixos is split into product vs personal,
  # keep overrides here and migrate "everyone would want this"
  # upstream into bnixos.

  # home-manager, sops/agenix, extra packages, etc. go here.
}
