{ ... }: {
  home.stateVersion = "24.11";

  programs = {
    chromium = {
      enable = true;
      commandLineArgs = [
        "--app=http://192.168.22.22:8123/kiosk-entryway/immich?kiosk"
        "--kiosk"
        "--noerrdialogs"
        "--disable-infobars"
        "--no-first-run"
        "--ozone-platform=wayland"
        "--enable-features=OverlayScrollbar"
        "--start-maximized"
        "--force-dark-mode"
        "--hide-crash-restore-bubble"
        "--hide-scrollbars"
      ];
    };
  };

}

