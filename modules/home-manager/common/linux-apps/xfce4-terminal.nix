{ pkgs, ... }: {
  home.file = {
    ".config/xfce4/terminal/accels.scm".source = ../../files/xfce4/terminal/accels.scm;
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
}