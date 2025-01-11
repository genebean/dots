{ ... }: {
  home.stateVersion = "24.11";

  programs = {
    chromium = {
      enable = true;
      commandLineArgs = [
        #"http://192.168.22.22:8123/kiosk-gene-desk/0?kiosk"
        "--app=http://192.168.20.190:3001/?album=e2281831-ae1b-45a5-8fe1-0a267ba5e1a9&transtion=cross-fade"
        "--kiosk"
        "--noerrdialogs"
        "--disable-infobars"
        "--no-first-run"
        "--ozone-platform=wayland"
        "--enable-features=OverlayScrollbar"
        "--start-maximized"
        "--force-dark-mode"
        "--hide-crash-restore-bubble"
      ];
    };
  };

}

