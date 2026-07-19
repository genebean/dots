{
  home.stateVersion = "24.11";

  genebean.services.chromium-kiosk = {
    enable = true;
    dashboardUrl = "http://192.168.22.22:8123/kiosk-entryway/immich?kiosk";
    extraCommandLineArgs = [ "--hide-scrollbars" ];
  };
}
