{ pkgs, ... }: {
  imports = [
    ./dconf.nix
  ];
  home.file = {
    ".config/hypr/frappe.conf".source = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "hyprland";
      rev = "99a88fd21fac270bd999d4a26cf0f4a4222c58be";
      hash = "sha256-07B5QmQmsUKYf38oWU3+2C6KO4JvinuTwmW1Pfk8CT8=";
    } + "/themes/frappe.conf");
    ".config/tilix/schemes/Beanbag-Mathias.json".source = ./files/tilix/Beanbag-Mathias.json;
    ".config/tilix/schemes/Catppuccin-Frappe.json".source = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "tilix";
      rev = "3fd05e03419321f2f2a6aad6da733b28be1765ef";
      hash = "sha256-SI7QxQ+WBHzeuXbTye+s8pi4tDVZOV4Aa33mRYO276k=";
    } + "/src/Catppuccin-Frappe.json");
    ".config/waybar/config".source = ./files/waybar/config;
    ".config/waybar/frappe.css".source = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "waybar";
      rev = "f74ab1eecf2dcaf22569b396eed53b2b2fbe8aff";
      hash = "sha256-WLJMA2X20E5PCPg0ZPtSop0bfmu+pLImP9t8A8V4QK8=";
    } + "/themes/frappe.css");
    ".config/waybar/style.css".source = ./files/waybar/style.css;
    ".config/xfce4/terminal/accels.scm".source = ./files/xfce4/terminal/accels.scm;
  };

  programs = {
    # Linux-specific aliases
    zsh.shellAliases = {
      nixup = "sudo nixos-rebuild switch --flake ~/repos/dots";
      uwgconnect = "nmcli dev wifi connect SecureWest password";
      uwgforget = "nmcli connection delete SecureWest";
      ykey = "sudo systemctl restart pcscd && sudo pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L";
    };
    # Using file in ./files/waybar/ to configure waybar
    waybar.enable = true;
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        frame_color = "#8CAAEE";
        separator_color= "frame";
      };

      urgency_low = {
        background = "#303446";
        foreground = "#C6D0F5";
      };

      urgency_normal = {
        background = "#303446";
        foreground = "#C6D0F5";
      };

      urgency_critical = {
        background = "#303446";
        foreground = "#C6D0F5";
        frame_color = "#EF9F76";
      };
    };
  };

  xfconf.settings = {
    xfce4-terminal = {
      "background-mode" = "TERMINAL_BACKGROUND_TRANSPARENT";
      "background-darkness" = "0.90000000000000000";
      "color-foreground" = "#e3e3ea";
      "color-background" = "#08052b";
      "color-cursor" = "#ff7f7f";
      "color-cursor-use-default" = false;
      "color-palette" = "#000000;#e52222;#a6e32d;#fc951e;#c48dff;#fa2573;#67d9f0;#f2f2f2;#555555;#ff5555;#55ff55;#ffff55;#5555ff;#ff55ff;#55ffff;#ffffff";
      "font-name" = "Hack Nerd Font Mono 12";
      "misc-always-show-tabs" = false;
      "misc-bell" = false;
      "misc-bell-urgent" = true;
      "misc-borders-default" = true;
      "misc-cursor-blinks" = false;
      "misc-cursor-shape" = "TERMINAL_CURSOR_SHAPE_BLOCK";
      "misc-default-geometry" = "120x24";
      "misc-inherit-geometry" = false;
      "misc-menubar-default" = true;
      "misc-mouse-autohide" = false;
      "misc-mouse-wheel-zoom" = true;
      "misc-toolbar-default" = false;
      "misc-confirm-close" = true;
      "misc-cycle-tabs" = true;
      "misc-tab-close-buttons" = true;
      "misc-tab-close-middle-click" = true;
      "misc-tab-position" = "GTK_POS_TOP";
      "misc-highlight-urls" = true;
      "misc-middle-click-opens-uri" = false;
      "misc-copy-on-select" = false;
      "misc-show-relaunch-dialog" = true;
      "misc-rewrap-on-resize" = true;
      "misc-slim-tabs" = true;
      "misc-new-tab-adjacent" = false;
      "misc-search-dialog-opacity" = "100";
      "misc-show-unsafe-paste-dialog" = true;
      "scrolling-unlimited" = true;
      "title-initial" = "xfce4-terminal";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Catppuccin Theme
      source = "~/.config/hypr/frappe.conf";

      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor = ",preferred,auto,auto";

      exec-once = [
        "waybar & dunst & ulauncher"

        # start polkit-kde-agent
        "/nix/store/$(ls -la /nix/store | grep polkit-kde-agent | grep '^d' | awk '{print $9}')/libexec/polkit-kde-authentication-agent-1"
      ];

      # Some default env vars.
      env = "XCURSOR_SIZE,24";

      input = {
        follow_mouse = 1;

        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        touchpad = {
          natural_scroll = "no";
        };

        # -1.0 - 1.0, 0 means no modification.
        sensitivity = 0;
      };

      general = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        gaps_in = 5;
        gaps_out = 20;
        layout = "dwindle";
      };

      decoration = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        "col.shadow" = "rgba(1a1a1aee)";
        drop_shadow = "yes";
        rounding = 10;
        shadow_range = 4;
        shadow_render_power = 3;
      };

      animations = {
        enabled = "yes";

        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more

        # master switch for pseudotiling.
        # Enabling is bound to mainMod + P in the keybinds section below
        pseudotile = "yes";

        preserve_split = "yes"; # you probably want this
      };

      master = {
        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        new_is_master = true;
      };

      gestures = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        workspace_swipe = "off";
      };

      # Example per-device config
      # See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
      "device:epic-mouse-v1" = {
        sensitivity = "-0.5";
      };

      # Example windowrule v1
      # windowrule = float, ^(kitty)$
      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

      # See https://wiki.hyprland.org/Configuring/Keywords/ for more
      "$mainMod" = "SUPER";

      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      bind = [
        "$mainMod, T, exec, tilix"
        "$mainMod, Return, exec, xfce4-terminal"
        "$mainMod, F, exec, firefox"
        "$mainMod, S, exec, slack"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, nautilus"
        "$mainMod, V, togglefloating,"
        "$mainMod, space, exec, ulauncher-toggle"
        "$mainMod, P, pseudo," # dwindle
        "$mainMod, J, togglesplit," # dwindle

        # Move focus with mainMod + arrow keys
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Laptop keys along the top
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      binde = [
        # Example volume button that allows press and hold, volume limited to 100%
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];

      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    }; # end settings
  }; # end hyprland
}

