{ ... }: {
  home.stateVersion = "24.11";

  programs = {
    chromium = {
      enable = true;
      commandLineArgs = [
        "http://192.168.22.22:8123/kiosk-gene-desk"
        "--kiosk"
        "--noerrdialogs"
        "--disable-infobars"
        "--no-first-run"
        "--ozone-platform=wayland"
        "--enable-features=OverlayScrollbar"
        "--start-maximized"
      ];
    };
  };

}

