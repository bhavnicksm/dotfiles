{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.username = "bhavnick";
  home.homeDirectory = "/home/bhavnick";
  home.stateVersion = "25.05";

  # Manage zsh + starship as the default shell.
  # OPENROUTER_API_KEY (hm-session-vars) is sourced via ~/.zshrc.
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
  };

  # Fuzzy finder: Ctrl+R history menu, Ctrl+T files, Alt+C cd
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # The authoritative prompt config lives at config/starship.toml.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./config/starship.toml);
  };

  # Sops secrets
  sops = {
    age.keyFile = "/home/bhavnick/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets.OPENROUTER_API_KEY = { };
  };

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
    zsh
    starship
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
    age
    sops

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

  # Terminal emulator: Ghostty with the Flexoki light theme
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "flexoki-light";
      font-family = "JetBrainsMono Nerd Font";
      keybind = [
        "ctrl+shift+h=new_split:left"
        "ctrl+shift+j=new_split:down"
        "ctrl+shift+k=new_split:up"
        "ctrl+shift+l=new_split:right"
        "ctrl+shift+p=write_screen_file:paste"
        "alt+h=goto_split:left"
        "alt+j=goto_split:down"
        "alt+k=goto_split:up"
        "alt+l=goto_split:right"
      ];
    };
  };

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
    OPENROUTER_API_KEY = "$(cat ${config.sops.secrets.OPENROUTER_API_KEY.path})";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Managed dotfiles — single source of truth is ./config/ (see config.nix)
  xdg.configFile = import ./config.nix { inherit lib; };

  # Personal helper scripts (launcher, theme selector)
  home.file = {
    ".local/bin/launcher.sh".source = ./bin/launcher.sh;
    ".local/bin/launcher.sh".executable = true;
    ".local/bin/theme-selector.sh".source = ./bin/theme-selector.sh;
    ".local/bin/theme-selector.sh".executable = true;
  };
}
