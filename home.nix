{ config, pkgs, inputs, lib, browser, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./themes/theme-module.nix
    inputs.bnixos.homeModules.bbar
    inputs.bnixos.homeModules.blaunch
    inputs.bnixos.homeModules.bipc
    inputs.bnixos.homeModules.bbinds
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
        # The bind list + modifier are owned by the bbinds home module
        # (inputs.bnixos.homeModules.bbinds): keybinds.hyprlandBind is the
        # rendered [ { _args = [...] } ] list, keybinds.hyprlandModifier the
        # `local mod` splice. Inherit the bnixos defaults and override
        # declaratively in the `keybinds` block further down.
      in
      {
        # Basic Settings: `local mod = "SUPER"` (was `$mod`). Comes from
        # bbinds so there is exactly one place to set the modifier.
        mod = config.keybinds.hyprlandModifier;

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

        # No autostart hook: bbar/dunst/hyprpaper are systemd.user.services,
        # gnome-keyring via services.gnome-keyring, and the cursor theme via
        # home.sessionVariables (HYPRCURSOR_*/XCURSOR_*). The module's systemd
        # activation hook is generated automatically.

        # Keybindings for Hyprland — inherited from bbinds (bnixos
        # flakes/bbinds): the single place that defines WM keybindings. The
        # defaults live in `keybinds.bind` there; this machine's tweaks are
        # in the `keybinds` block in this file.
        bind = config.keybinds.hyprlandBind;
      };
  };

  # The per-machine keybindings. The defaults are inherited from bnixos
  # (inputs.bnixos.homeModules.bbinds); change them declaratively here via
  # `keybinds.override` (deep-merged over the defaults, null = remove):
  #   keybinds.override.<name>.key = "…";   # rebind a key only
  #   keybinds.override.<name>     = null;  # drop a default binding
  #   keybinds.override.my-script  = { key = "…"; exec = "…"; }  # add one
  keybinds.enable = true;
  # Machine-specific overrides on the bnixos defaults:
  keybinds.override.browser = { key = "P"; exec = "${lib.getExe browser} --new-window"; }; # bnixos.packages.browser
  keybinds.override.menu = { key = "B"; exec = "~/.local/bin/bt-menu.sh"; }; # bt scripts
  systemd.user.services = {
    # Scoped to hyprland-session.target (started by Hyprland's own activation
    # hook AFTER dbus-update-activation-environment sets the Wayland env).
    # NOTE: do NOT add After=hydration here — After=hyprland-session.target
    # combined with this WantedBy created a systemd ordering cycle that
    # deleted every start job (bbar/hyprpaper never launched).
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

  # The status bar is bbar (bnixos flakes/bbar) — a Quickshell desktop bar.
  # Waybar is deliberately gone: the bar is owned by bnixos so there is one
  # place to edit it. The palette is wired from the active theme in
  # themes/theme-module.nix; bbar runs via its own systemd.user.services.bbar.
  bbar.enable = true;

  # The launcher is blaunch (bnixos flakes/blaunch) — a Quickshell app menu.
  # It takes over both the fuzzel app search ($mod SPACE → bl-launch) and the
  # `--dmenu` prompts scripts used (bt-menu.sh → bl-select). The palette is
  # wired from the active theme in themes/theme-module.nix; it runs via its
  # own systemd.user.services.blaunch.
  blaunch.enable = true;

  # The shared Quickshell IPC client (b-ipc) bl-launch/bl-select prefer.
  bipc.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment. The full default desktop (shell, Hyprland stack, secrets,
  # font, browser) ships via bnixos.packages.core — see bnixos/packages.nix.
  # Keep here only packages that are personal to this machine and not part of
  # the bnixos core set (unfree/individual apps, extra pywal tooling).
  home.packages = with pkgs; [
    # Utility for dynamic theme colors, driven by the active theme.
    pywal

    # Desktop applications (unfree / personal)
    spotify
    code-cursor-fhs
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
