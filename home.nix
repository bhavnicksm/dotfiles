{ config, pkgs, inputs, lib, browser, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.bnixos.homeModules.btheme
    inputs.bnixos.homeModules.bshell
    inputs.bnixos.homeModules.bnight
    inputs.bnixos.homeModules.bbar
    inputs.bnixos.homeModules.blaunch
    inputs.bnixos.homeModules.bipc
    inputs.bnixos.homeModules.bblue
    inputs.bnixos.homeModules.bbinds
    inputs.bnixos.homeModules.bnotif
    inputs.bnixos.homeModules.bnixvim
  ];

  home.username = "bhavnick";
  home.homeDirectory = "/home/bhavnick";
  home.stateVersion = "26.05";

  # Declarative theme (Omarchy-style). The color catalog lives in
  # themes/palettes.nix; wallpapers are resolved to store paths here — the
  # btheme contract wants absolute/store-path strings. Switch themes by
  # editing btheme.name and rebuilding. See docs/theming.md.
  btheme.name = "white";
  btheme.themes =
    builtins.mapAttrs (_: p:
      p // (lib.optionalAttrs ((p ? wallpaper) && (p.wallpaper != null)) {
        wallpaper = "${./wallpapers}/${p.wallpaper}";
      })
    ) (import ./themes/palettes.nix);

  # The shell experience (zsh + starship + CLI tools + ghostty defaults)
  # ships with bnixos via bshell; only personal/workflow aliases live here.
  bshell.enable = true;
  programs.zsh.shellAliases = {
    # ~/dotfiles is the canonical symlink to this repo
    nrb = "sudo nixos-rebuild switch --flake ~/dotfiles#dotfiles";
    sec = "sops ~/Projects/dotfiles/secrets.yaml";
    ncl = "sudo nix-collect-garbage -d";
  };

  # Prompt layout/format (Gruvbox Rainbow powerline preset). Colors are NOT
  # in this TOML: btheme supplies settings.palette + settings.palettes.<name>
  # so the prompt follows the active theme.
  programs.starship.settings = builtins.fromTOML (builtins.readFile ./config/starship.toml);

  # Export EVERY sops secret as a per-shell env var (initContent runs on
  # every .zshrc source, so new secrets picked up without logout — unlike
  # home.sessionVariables whose hm-session-vars.sh once-guard goes stale).
  programs.zsh.initContent =
    let
      exports = lib.mapAttrsToList (name: _:
        "export ${name}=\"\$(cat ${config.sops.secrets.${name}.path})\""
      ) config.sops.secrets;
    in
    lib.concatStringsSep "\n" exports;

  # Sops secrets
  sops = {
    age.keyFile = "/home/bhavnick/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    # Auto-declare every secret: top-level keys of secrets.yaml are
    # plaintext even in the encrypted file, so parse them at eval time.
    # Each key becomes `sops.secrets.<name> = { };` and is exported as an
    # env var per-shell via programs.zsh.initContent above (NOT
    # home.sessionVariables — HM's hm-session-vars.sh once-guard makes
    # sessionVariables stale for any secret added after login).
    secrets =
      let
        topLevelKeys =
          builtins.filter
            (x: x != null)
            (map
              (line:
                let m = builtins.match "^([A-Za-z_][A-Za-z0-9_]+): .*" line;
                in if m == null then null else builtins.head m)
              (lib.splitString "\n" (builtins.readFile ./secrets.yaml)));
      in
      lib.genAttrs topLevelKeys (_: { });
  };

  # Setting the cursor theme to use (personal choice, deliberately not a
  # bnixos default).
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
  #
  # Everything else is owned upstream now:
  #   - desktop look defaults (gaps/borders/rounding/shadows/animations/
  #     splash) + themed border colors → btheme (bnixos flakes/btheme)
  #   - window rules for the floating bblue-tui → bblue
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    settings =
      let
        # The bind list + modifier are owned by the bbinds home module
        # (inputs.bnixos.homeModules.bbinds): keybinds.hyprlandBind is the
        # rendered [ { _args = [...] } ] list, keybinds.hyprlandModifier the
        # `local mod` splice.
      in
      {
        # Basic Settings: `local mod = "SUPER"` (was `$mod`). Comes from
        # bbinds so there is exactly one place to set the modifier.
        mod = config.keybinds.hyprlandModifier;

        # Keybindings — inherited from bbinds; this machine's tweaks are in
        # the `keybinds.override` block below.
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

  # Machine-specific overrides on the bnixos defaults ($mod B and $mod I
  # need none: bbinds defaults open bluetui/wifitui in class-tagged
  # floating ghostty popups — same treatment for both TUIs).
  #
  # Universal tab-close ($mod+W) ships as a bbinds default now: it
  # branches on the classes in `keybinds.terminals` (upstream). The
  # remaining universal binds below branch on the focused window's class
  # at runtime (`hl.get_active_window()`), rendered from the data here so
  # adopting another app is a one-line change.
  keybinds.override =
    let
      # Chromium-family classes share one browser command. bnixos.packages
      # .browser resolves to google-chrome here; the chromium spellings are
      # kept so the map survives a browser swap.
      browserClasses = [ "google-chrome" "chromium" "Chromium" ];
      # Class → command for the new-window bind (strict map: an unmapped
      # class does nothing — most single-instance apps refocus instead of
      # opening a new window unless invoked with explicit flags).
      # Thunar is the bnixos default file manager. Keys are window CLASSES
      # (live-verified via `hyprctl activewindow -j`): ghostty's app_id is
      # the reverse-DNS form here.
      windowCommands = {
        "com.mitchellh.ghostty" = "ghostty";
        thunar = "thunar --new-window";
        nautilus = "nautilus --new-window";
      } // lib.genAttrs browserClasses (_: "${lib.getExe browser} --new-window");
    in
    {
      # bnixos.packages.browser
      browser = { key = "P"; exec = "${lib.getExe browser} --new-window"; };

      # DND moves off $mod+N (which becomes the universal new-window):
      # partial override keeps bbinds' bnotif exec.
      dnd = { key = "N"; shift = true; }; # $mod+SHIFT+N

      # Universal new tab ($mod+T): forward each app family's own chord;
      # terminal classes come from bbinds' `keybinds.terminals`.
      tab-new = {
        key = "T";
        inline = ''
          function()
            local w = hl.get_active_window()
            local cls = w and w.class or ""
            local terms = { ${lib.concatStringsSep " " (map (c: ''["${c}"] = true,'') config.keybinds.terminals)} }
            if terms[cls] then
              hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL_SHIFT", key = "t" }))
            else
              hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "t" }))
            end
          end
        '';
      };

      # Universal new window ($mod+N).
      window-new = {
        key = "N";
        inline = ''
          function()
            local w = hl.get_active_window()
            local cmds = { ${lib.concatStringsSep " " (lib.mapAttrsToList (c: cmd: ''["${c}"] = ${builtins.toJSON cmd},'') windowCommands)} }
            local cmd = w and cmds[w.class]
            if cmd then
              hl.dispatch(hl.dsp.exec_cmd(cmd))
            end
          end
        '';
      };
    };

  systemd.user.services = {
    # Scoped to hyprland-session.target (started by Hyprland's own activation
    # hook AFTER dbus-update-activation-environment sets the Wayland env).
    # NOTE: do NOT add After=hydration here — After=hyprland-session.target
    # combined with this WantedBy created a systemd ordering cycle that
    # deleted every start job (bbar/hyprpaper never launched).

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

  # The status bar is bbar (bnixos flakes/bbar) — a Quickshell desktop bar,
  # themed from the active palette via btheme. Runs via its own
  # systemd.user.services.bbar.
  bbar.enable = true;

  # The launcher is blaunch (bnixos flakes/blaunch) — a Quickshell app menu.
  # It takes over both the app search ($mod SPACE → bl-launch) and the dmenu
  # prompts (`bl-select`). Themed by btheme; runs via its own service.
  blaunch.enable = true;

  # Notifications are bnotif (bnixos flakes/bnotif) — a Quickshell freedesktop
  # notification server with themed toasts, persistent DND ($mod+SHIFT+N),
  # and the UPower battery watcher. Replaces dunst. Themed by btheme.
  bnotif.enable = true;

  # The shared Quickshell IPC client (b-ipc) bl-launch/bl-select prefer.
  bipc.enable = true;

  # Bluetooth is bblue (bnixos flakes/bblue) — the bt-* scripts at
  # ~/.local/bin (bt-menu.sh is manual-only; $mod B opens bluetui via the
  # bbinds default `bluetooth` bind), the persistent bt-agent pairing
  # service, and bluetui, which both that bind and the bbar Bluetooth
  # widget open in a floating ghostty (class bblue-tui; floated by
  # windowrules the module ships itself).
  bblue.enable = true;
  bblue.tui.enable = true;

  # Night light is bnight (bnixos flakes/bnight) — hyprsunset with a systemd
  # user unit and the default schedule (identity by day, warm from 19:00).
  bnight.enable = true;

  # The editor is bnixvim (bnixos flakes/bnixvim) — nixvim-based, themed
  # from the active palette via btheme. It owns ~/.config/nvim.
  bnixvim.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment. The full default desktop (shell, Hyprland stack, secrets,
  # font, browser, CLI tools) ships via bnixos.packages.core — see
  # bnixos/packages.nix. Keep here only packages that are personal to this
  # machine and not part of the bnixos core set.
  home.packages = with pkgs; [
    # Utility for dynamic theme colors, driven by the active theme.
    pywal

    # Desktop applications (unfree / personal)
    spotify
    code-cursor-fhs

    # Nix language server (opencode lsp)
    nil

    # Python + uv for ML/dev workspaces (silver-searcher, gym/dirth)
    python312
    uv
  ];

  # Setting the font
  fonts.fontconfig.enable = true;

  # Terminal emulator: Ghostty ships with static defaults (font-family,
  # split keybinds, compact tab CSS) from bshell and colors from btheme.
  # Only machine-specific tweaks here:
  programs.ghostty.settings.font-size = 10;

  # gnome-keyring is system-owned (bnixos configuration.nix:
  # services.gnome.gnome-keyring.enable): PAM auto_start unlocks the login
  # keyring at SDDM login and D-Bus activation starts the daemon on demand.
  # No HM services.gnome-keyring / hand-written dbus service file here.

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
  # Secrets are NOT exported here: HM's hm-session-vars.sh once-guard
  # (__HM_SESS_VARS_SOURCED) goes stale for any secret added after login.
  # Secrets are exported per-shell in programs.zsh.initContent above.
  # Session variables here are only for always-resident static values.
  home.sessionVariables =
    {
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
    # Force Electron's safeStorage backend to gnome-libsecret: on Hyprland
    # (XDG_CURRENT_DESKTOP=Hyprland) Chromium's os_crypt autodetection does
    # not pick the keyring and Cursor shows "An OS keyring couldn't be
    # identified for storing the encryption related data".
    ".config/Cursor/argv.json".text = builtins.toJSON { password-store = "gnome-libsecret"; };
  };
}
