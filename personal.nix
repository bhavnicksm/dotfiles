{ config, lib, pkgs, inputs, ... }:

let
  palettes = import ./themes/palettes.nix;
  activeTheme = config.home-manager.users.bhavnick.themes.theme or "white";
  palette = palettes.${activeTheme};

  # Replace {{ token }} placeholders in a template file.
  renderTemplate = template: attrs:
    builtins.foldl'
      (text: name: builtins.replaceStrings [ "{{ ${name} }}" ] [ attrs.${name} ] text)
      template
      (builtins.attrNames attrs);

  # "#rrggbb" + alpha (0-1) -> QML "#AARRGGBB" color string.
  qColor = hex: alpha:
    "#${lib.toHexString (builtins.floor (alpha * 255))}${lib.removePrefix "#" hex}";

  wallpaperPath = "${./wallpapers}/${palette.wallpaper}";

  # Omarchy-style SDDM theme, generated from the active palette so the login
  # screen matches hyprlock (see themes/sddm/main.qml.tpl).
  sddmTheme = pkgs.runCommandLocal "sddm-theme-white" { } ''
    mkdir -p $out/share/sddm/themes/white
    cat > $out/share/sddm/themes/white/Main.qml <<'QML'
      ${renderTemplate (builtins.readFile ./themes/sddm/main.qml.tpl) {
        wallpaper = wallpaperPath;
        dimOverlay = qColor "#000000" 0.3;
        cardFill = qColor "#ffffff" 0.85;
        cardBorder = palette.accent;
        textColor = palette.foreground;
        placeholderColor = qColor "#000000" 0.5;
        selection = palette.selection;
        errorColor = palette.red;
      }}
    QML
    cp ${./themes/sddm/theme.conf} $out/share/sddm/themes/white/theme.conf
    cp ${./themes/sddm/metadata.desktop} $out/share/sddm/themes/white/metadata.desktop
  '';
in
{
  # Machine identity + anything that is *you*, not the product.
  networking.hostName = "bnixos";
  time.timeZone = "America/Los_Angeles";

  # NixOS-level zsh support (PATH for the login shell)
  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bhavnick = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  # Themed, Omarchy-style login screen (overrides bnixos's catppuccin theme)
  services.displayManager.sddm.theme = lib.mkForce "white";
  environment.systemPackages = [ sddmTheme ];

  # Tailscale mesh VPN daemon
  services.tailscale.enable = true;

  # Allow only clearly-flagged unfree packages we intentionally use.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "spotify" "cursor" ];

  # Greeter + plymouth render JetBrains Mono (user-level HM fonts are not
  # visible to processes running as root/sddm).
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

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