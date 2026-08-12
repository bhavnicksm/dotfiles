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

  # Add Hyprland configuration to the home.
  # stateVersion 26.05 defaults `configType` to "lua" (Hyprland >= 0.55
  # deprecated hyprlang in favour of `~/.config/hypr/hyprland.lua`). The
  # `settings` below use the 26.05 Lua generator: each attr becomes an
  # `hl.<name>(…)` call; `_var` makes a Lua local; `_args` are the args
  # (mkLuaInline = raw Lua). See docs/hyprland-lua.md.
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    settings =
      let
        inline = lib.generators.mkLuaInline;
        # key strings reuse the `mod` local (SUPER) defined below.
        m  = key: inline "mod .. \" + ${key}\"";
        ms = key: inline "mod .. \" + SHIFT + ${key}\"";
        exec  = cmd: inline ''hl.dsp.exec_cmd("${cmd}")'';
        focus = dir: inline ''hl.dsp.focus({ direction = "${dir}" })'';
        swap  = dir: inline ''hl.dsp.window.swap({ direction = "${dir}" })'';
        ws    = w: inline ''hl.dsp.focus({ workspace = "${w}" })'';
        movews = w: inline ''hl.dsp.window.move({ workspace = "${w}", follow = true })'';
      in
      {
        # Basic Settings: `local mod = "SUPER"` (was `$mod`)
        mod._var = "SUPER";

        # Plain config options (general/decoration/animations) go through a
        # single `hl.config({ … })` call — there is no hl.general/hl.decoration/
        # hl.animations function in Hyprland's Lua API.
        config = {
          general = {
            gaps_in = 3;      # Gap between windows (default is 5)
            gaps_out = 6;     # Gap between windows and screen edge (default is 20)
            border_size = 2;  # Window border thickness (default is 1)
            # "col.active_border" / "col.inactive_border" come from the active
            # theme via themes/theme-module.nix (Lua "rgba(r,g,b,a)" format).
          };

          # Subtle rounded window corners
          decoration = {
            rounding = 6;
          };

          # Setting the animations to false for now
          animations = {
            enabled = false;
          };

          # No default wallpaper/splash flash while hyprpaper loads: full
          # black background until the themed wallpaper is live.
          misc = {
            background_color = "0x000000";
            disable_splash_rendering = true;
          };
        };

        # No autostart hook: waybar/dunst/hyprpaper are systemd.user.services,
        # gnome-keyring via services.gnome-keyring, and the cursor theme via
        # home.sessionVariables (HYPRCURSOR_*/XCURSOR_*). The module's systemd
        # activation hook is generated automatically.

        # Keybindings for Hyprland
        bind = [
          { _args = [ (m "RETURN") (exec "ghostty") ]; }
          { _args = [ (m "SPACE") (exec "~/.local/bin/launcher.sh") ]; }
          { _args = [ (m "B") (exec "~/.local/bin/bt-menu.sh") ]; }
          { _args = [ (m "W") (inline "hl.dsp.window.close()") ]; }          # killactive
          { _args = [ (m "M") (inline "hl.dsp.exit()") ]; }                  # exit
          { _args = [ (m "E") (exec "thunar") ]; }
          { _args = [ (m "V") (inline "hl.dsp.window.float({ action = \"toggle\" })") ]; } # togglefloating
          { _args = [ (m "P") (inline "hl.dsp.window.pseudo({ action = \"toggle\" })") ]; } # pseudo
          # togglesplit: no hl.dsp.window.split on 0.55; best-effort via the
          # dwindle layout message. REVISIT (see docs/hyprland-lua.md).
          { _args = [ (m "J") (inline "hl.dsp.layout(\"togglesplit\")") ]; }
          { _args = [ (m "L") (exec "hyprlock") ]; }

          # Move focus
          { _args = [ (m "left") (focus "l") ]; }
          { _args = [ (m "right") (focus "r") ]; }
          { _args = [ (m "up") (focus "u") ]; }
          { _args = [ (m "down") (focus "d") ]; }

          # Swap the focused window with its neighbor within the workspace
          { _args = [ (ms "left") (swap "l") ]; }
          { _args = [ (ms "right") (swap "r") ]; }
          { _args = [ (ms "up") (swap "u") ]; }
          { _args = [ (ms "down") (swap "d") ]; }

          # Switch Workspaces
          { _args = [ (m "1") (ws "1") ]; }
          { _args = [ (m "2") (ws "2") ]; }
          { _args = [ (m "3") (ws "3") ]; }
          { _args = [ (m "4") (ws "4") ]; }
          { _args = [ (m "5") (ws "5") ]; }
          { _args = [ (m "6") (ws "6") ]; }
          { _args = [ (m "7") (ws "7") ]; }
          { _args = [ (m "8") (ws "8") ]; }
          { _args = [ (m "9") (ws "9") ]; }

          # Shift window to workspace
          { _args = [ (ms "1") (movews "1") ]; }
          { _args = [ (ms "2") (movews "2") ]; }
          { _args = [ (ms "3") (movews "3") ]; }
          { _args = [ (ms "4") (movews "4") ]; }
          { _args = [ (ms "5") (movews "5") ]; }
          { _args = [ (ms "6") (movews "6") ]; }
          { _args = [ (ms "7") (movews "7") ]; }
          { _args = [ (ms "8") (movews "8") ]; }
          { _args = [ (ms "9") (movews "9") ]; }

          # Scroll through the workspaces
          { _args = [ (m "mouse_down") (ws "e+1") ]; }
          { _args = [ (m "mouse_up") (ws "e-1") ]; }

          # Screenshots ($( … ) expands via the exec_cmd shell)
          { _args = [ "Print" (inline ''hl.dsp.exec_cmd("grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png")'') ]; }
          { _args = [ (m "Print") (inline ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png")'') ]; }
          { _args = [ "SHIFT + Print" (inline ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'') ]; }

          # Media keys (was bindl = locked-screen binds)
          { _args = [ "XF86AudioRaiseVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { locked = true; } ]; }
          { _args = [ "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { locked = true; } ]; }
          { _args = [ "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { locked = true; } ]; }
          { _args = [ "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") { locked = true; } ]; }
          { _args = [ "XF86MonBrightnessUp" (exec "brightnessctl set 5%+") { locked = true; } ]; }
          { _args = [ "XF86MonBrightnessDown" (exec "brightnessctl set 5%-") { locked = true; } ]; }
        ];
      };
  };

  # Desktop daemons run as declarative user services (modular, restarted on
  # failure) instead of inline autostart Lua. They start once the graphical
  # session is up (hyprland-session.target guarantees the Wayland env).
  systemd.user.services = {
    # Scoped to hyprland-session.target (started by Hyprland's own activation
    # hook AFTER dbus-update-activation-environment sets the Wayland env).
    # NOTE: do NOT add After=hydration here — After=hyprland-session.target
    # combined with this WantedBy created a systemd ordering cycle that
    # deleted every start job (waybar/hyprpaper never launched).
    waybar = {
      Unit = {
        Description = "Waybar status bar";
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "hyprland-session.target" ]; };
    };

    dunst = {
      Unit = {
        Description = "Dunst notification daemon";
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.dunst}/bin/dunst";
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "hyprland-session.target" ]; };
    };

    hyprpaper = {
      Unit = {
        Description = "Hyprland wallpaper daemon";
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper";
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "hyprland-session.target" ]; };
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
  home.sessionVariables =
    # Export EVERY sops secret as an env var named after the secret
    # (e.g. OPENROUTER_API_KEY -> "$(cat <decrypted path>)").
    # NOTE: env vars are visible to every process + child (/proc/<pid>/environ,
    # logs); prefer read-from-file unless a secret must be in the environment.
    (builtins.mapAttrs (name: _: "$(cat ${config.sops.secrets.${name}.path})") config.sops.secrets)
    // {
      # Cursor theme for Hyprland/hyprcursor + GTK (declarative replacement
      # for the old `hyprctl setcursor` exec; matches home.pointerCursor below).
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "16";
      HYPRCURSOR_THEME = "Bibata-Modern-Classic";
      HYPRCURSOR_SIZE = "16";
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
