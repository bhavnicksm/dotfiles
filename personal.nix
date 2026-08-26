{ config, lib, pkgs, inputs, ... }:

let
  palettes = import ./themes/palettes.nix;
  activeTheme = config.home-manager.users.bhavnick.btheme.name or "white";
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

  # Bluetooth: kernel + bluetoothd now ship from bnixos configuration.nix
  # (enable/powerOnBoot/Pairable). The user-space half is the bblue module
  # (bnixos flakes/bblue) wired in home.nix: bt-* scripts, bt-agent service,
  # bluetui TUI.

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bhavnick = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;

    # Public keys allowed to SSH in as this user. Only keys listed here can
    # get in — see the openssh block below (PasswordAuthentication=false).
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIqd125sj1Xv1jPykhtZrq2aIAs35qCbO/KCWC3hJJ7F bhavnicksm@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2+cdedFeG1SglKFfGIdDu0kzZ/Vjgo9bZvPiHlEdOn bhavnick-bnixos-tailscale"
    ];
  };

  # Secure by default SSH: daemon ran only because we deliberately flipped
  # this on; accepts key auth for a curated list of users (no passwords),
  # never root, no X11 forwarding, and logs verbosely.
  services.openssh = {
    enable = true;
    # openFirewall defaults to true → adds a global allow-22 rule on EVERY
    # interface, which would undo the LAN+tailscale scoping below. The
    # explicit per-interface firewall rules handle reachability instead.
    openFirewall = false;
    settings = {
      # Keys only — a lost key is far preferable to a brute-forced password.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      # Nobody logs in as root over SSH; sudo does that, authenticated locally.
      PermitRootLogin = "no";
      # Only these (existing) users may log in over SSH.
      AllowUsers = [ "bhavnick" ];
      # No remote X11 / agent trust pushes.
      X11Forwarding = false;
      AllowAgentForwarding = false;
      # Better bad-login accounting.
      LogLevel = "VERBOSE";
      # Maximum auth tries before disconnecting; fewer = less brute-force room.
      MaxAuthTries = 3;
    };
  };

  # Reachability for sshd: open port 22 **only** on the LAN wifi interface
  # and the tailscale interface. Nothing is exposed to the public internet;
  # the rest of the firewall stays at its default (drop). Re-audit if the
  # wifi interface name changes.
  networking.firewall.interfaces = {
    "wlp192s0".allowedTCPPorts = [ 22 ];
    "tailscale0".allowedTCPPorts = [ 22 ];
  };

  # Themed, Omarchy-style login screen (overrides bnixos's catppuccin theme)
  services.displayManager.sddm.theme = lib.mkForce "white";
  environment.systemPackages = [ sddmTheme ];

  # Tailscale mesh VPN daemon
  services.tailscale.enable = true;

  # Unfree apps we intentionally use, layered onto bnixos's own allowance
  # (the product allows its default browser; see bnixos configuration.nix).
  bnixos.packages.allowUnfree = [ "spotify" "cursor" ];

  # Keep `opencode` on the latest (nixpkgs-unstable) instead of the 26.05
  # branch's broken 1.15.10 (its DB migration fails against our 1.18.x data
  # dir). Everything else stays pinned to the 26.05 branch.
  nixpkgs.overlays = [
    (final: prev: {
      opencode = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode;
    })
  ];

  # Home-manager: personal configuration, packages, and services
  imports = [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.bhavnick = import ./home.nix;
        extraSpecialArgs = {
          inherit inputs;
          browser = config.bnixos.packages.browser;
        };
      };
    }
  ];
}