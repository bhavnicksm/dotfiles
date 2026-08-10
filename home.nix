{ config, pkgs, ... }:

{
  home.username = "bhavnick";
  home.homeDirectory = "/home/bhavnick";
  home.stateVersion = "25.05";
  
  # Setting the cursor theme to use
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  # Add Hyprland configuration to the home
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Basic Settings
      "$mod" = "SUPER";

      # General settings
      general = {
        gaps_in = 3;      # Gap between windows (default is 5)
        gaps_out = 6;     # Gap between windows and screen edge (default is 20)
        border_size = 2;  # Window border thickness (default is 1)
        "col.active_border" = "rgb(076678)";    # Gruvbox blue for active window
        "col.inactive_border" = "rgb(928374)";  # Gruvbox gray for inactive
      };

      # Setting the animations to false for now
      animations = {
        enabled = false;
      };

      # Setting the cursor theme
      exec-once = [
        "waybar"
	"dunst"
	"hyprpaper"
        "hyprctl setcursor Bibata-Modern-Classic 16"
	"gnome-keyring-daemon --start --components=secrets"
      ];

      # Keybindings for Hyprland
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, SPACE, exec, ~/.local/bin/launcher.sh"
	"$mod, W, killactive,"
	"$mod, M, exit,"
	"$mod, E, exec, thunar"
	"$mod, V, togglefloating,"
	"$mod, P, pseudo,"
 	"$mod, J, togglesplit,"
	"$mod, L, exec, hyprlock"
	# Move focus
	"$mod, left, movefocus, l"
	"$mod, right, movefocus, r"
	"$mod, up, movefocus, u"
	"$mod, down, movefocus, d"

	# Switch Workspaces
	"$mod, 1, workspace, 1"
	"$mod, 2, workspace, 2"
	"$mod, 3, workspace, 3"
	"$mod, 4, workspace, 4"
	"$mod, 5, workspace, 5"
	"$mod, 6, workspace, 6"
	"$mod, 7, workspace, 7"
	"$mod, 8, workspace, 8"
	"$mod, 9, workspace, 9"

	# Shift window to workspace
	"$mod SHIFT, 1, movetoworkspace, 1"
	"$mod SHIFT, 2, movetoworkspace, 2"
	"$mod SHIFT, 3, movetoworkspace, 3"
	"$mod SHIFT, 4, movetoworkspace, 4"
	"$mod SHIFT, 5, movetoworkspace, 5"
	"$mod SHIFT, 6, movetoworkspace, 6"
	"$mod SHIFT, 7, movetoworkspace, 7"
	"$mod SHIFT, 8, movetoworkspace, 8"
	"$mod SHIFT, 9, movetoworkspace, 9"

	# Scroll through the workspaces
	"$mod, mouse_down, workspace, e+1"
	"$mod, mouse_up, workspace, e-1"

	# Screenshots
        ", Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"  # Full screenshot
        "$mod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"  # Area screenshot
        "SHIFT, Print, exec, grim -g \"$(slurp)\" - | wl-copy"  # Screenshot to clipboard
      ];

      # Media keys bindings
      bindl = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];
    };
  };
  
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    
    # Basic Hyprland utils
    ghostty
    opencode
    fuzzel
    waybar
    dunst
    hyprpaper
    hyprlock
    hypridle
    
    # Support Utils
    pywal # dynamic waybar colors
    hyprpicker # color picker
    grim
    slurp
    cliphist
    wl-clipboard

    # Utils for secrets
    libsecret
    gnome-keyring

    # Additional CLI utils
    btop

    # Desktop applications 
    firefox
    zed-editor-fhs

    # Miscellaneous pkgs (fonts etc.)
    nerd-fonts.jetbrains-mono
  ];
  
  # Setting the font
  fonts.fontconfig.enable = true;

  # Adding the neovim options here
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    # Adding the vim plugins here
    plugins = with pkgs.vimPlugins; [
      gruvbox-nvim
    ];
  };
  
  # Adding all the home-manager services here

  # Adding the Gnome Keyring to manage the secrets
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];  # Just the secrets component
  };

  home.file.".local/share/dbus-1/services/org.freedesktop.secrets.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.secrets
    Exec=${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --foreground --components=secrets
  '';

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/bhavnick/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Personal helper scripts (launcher, theme selector)
  home.file = {
    ".local/bin/launcher.sh".source = ./bin/launcher.sh;
    ".local/bin/launcher.sh".executable = true;
    ".local/bin/theme-selector.sh".source = ./bin/theme-selector.sh;
    ".local/bin/theme-selector.sh".executable = true;
  };
}
