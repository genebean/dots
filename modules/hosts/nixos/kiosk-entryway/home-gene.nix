{
  config,
  ...
}:
{
  home.stateVersion = "24.11";

  genebean = {
    kiosk-hardware = {
      enable = true;
      wirelessInterface = "wlp3s0";
    };

    services = {
      chromium-kiosk = {
        enable = true;
        dashboardUrl = "http://192.168.22.22:8123/kiosk-entryway/immich?kiosk";
        extraCommandLineArgs = [ "--hide-scrollbars" ];
        wirelessInterface = config.genebean.kiosk-hardware.wirelessInterface;
      };
      kiosk-backups.enable = true;
    };
  };
}
