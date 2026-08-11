{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./themes/theme-module.nix
  ];

  home.username = "bhavnick";
  home.homeDirectory = "/home/bhavnick";
  home.stateVersion = "26.05";

  # Declarative theme (Omarchy-style). Options are the keys of
  # themes/palettes.nix: "white" | "gruvbox-light". Switch by editing this
  # one line and running `home-manager switch`. See docs/theming.md.
  themes.theme = "white";

  # Manage zsh + starship as the default shell.
  # OPENROUTER_API_KEY (hm-session-vars) is sourced via ~/.zshrc.
  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    autosuggestion.enable = true;
  };

  # Fuzzy finder: Ctrl+R history menu, Ctrl+T files, Alt+C cd
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Modern ls (eza) with icons and git status
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };

  # Smart cd: replace cd with zoxide (fuzzy match, falls back to real cd)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  # Terminal file manager
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # Syntax-highlighted pager for man/cat
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi"; # Follows the terminal palette (flexoki-light)
      pager = "less -FR";
    };
  };

  # Fast content search: rg <pattern> (also backs fzf's Ctrl+T)
  programs.ripgrep = {
    enable = true;
    arguments = [ "--smart-case" ];
  };

  # Interactive TUI for git operations
  programs.lazygit = {
    enable = true;
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
        # "col.active_border" / "col.inactive_border" come from the active
        # theme via themes/theme-module.nix.
      };

      # Subtle rounded window corners
      decoration = {
        rounding = 6;
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
	"$mod, B, exec, ~/.local/bin/bt-menu.sh"
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

	# Swap the focused window with its neighbor within the workspace
	"$mod SHIFT, left, swapwindow, l"
	"$mod SHIFT, right, swapwindow, r"
	"$mod SHIFT, up, swapwindow, u"
	"$mod SHIFT, down, swapwindow, d"

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
    bluez

# Desktop applications 
    firefox
    spotify
    code-cursor-fhs

    # Miscellaneous pkgs (fonts etc.)
    nerd-fonts.jetbrains-mono
  ];
  
  # Setting the font
  fonts.fontconfig.enable = true;

  # Terminal emulator: Ghostty themed from themes/palettes.nix via
  # themes/theme-module.nix (theme = programs.ghostty.themes.<theme>).
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 10;
      gtk-custom-css = "~/.config/ghostty/compact-tabs.css";
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

  # Compact Ghostty tab bar (requires gtk-custom-css above)
  home.file.".config/ghostty/compact-tabs.css".text = ''
    tabbar tabbox {
      min-height: 18px;
      padding-top: 1px;
      padding-bottom: 1px;
    }

    tabbar tab {
      min-height: 14px;
      padding: 0;
    }

    tabbar tab label,
    tabbar .start-action label,
    tabbar .end-action label {
      font-size: 9px;
    }

    tabbar tab button.image-button {
      min-width: 18px;
      min-height: 18px;
    }

    tabbar .start-action,
    tabbar .end-action {
      padding: 1px;
    }
  '';

  # Adding the neovim options here
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    # HM owns ~/.config/nvim/init.lua (declarative, idiomatic). The generated
    # plugin packpath setup is prepended automatically.
    initLua = ''
      -- Line numbers
      vim.opt.number = true           -- Show line numbers
      vim.opt.relativenumber = true   -- Show relative line numbers (optional)

      -- Basic settings that work well with line numbers
      vim.opt.cursorline = true       -- Highlight current line
      vim.opt.signcolumn = "yes"      -- Always show sign column

      -- Gruvbox theme settings
      vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
      vim.opt.background = "light"    -- Use light background

      -- gruvbox-nvim ships with this configuration (see plugins below)
      vim.cmd.colorscheme("gruvbox")
    '';

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
    ".local/bin/bt-menu.sh".source = ./bin/bt-menu.sh;
    ".local/bin/bt-menu.sh".executable = true;
    ".local/bin/bt-power.sh".source = ./bin/bt-power.sh;
    ".local/bin/bt-power.sh".executable = true;
    ".local/bin/bt-device.sh".source = ./bin/bt-device.sh;
    ".local/bin/bt-device.sh".executable = true;
    ".local/bin/bt-scan.sh".source = ./bin/bt-scan.sh;
    ".local/bin/bt-scan.sh".executable = true;
  };
}
