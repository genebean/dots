{
  config,
  ...
}:
{
  home.stateVersion = "24.11";

  genebean = {
    kiosk-hardware = {
      enable = true;
      wirelessInterface = "wlan0";
    };

    services = {
      chromium-kiosk = {
        enable = true;
        dashboardUrl = "http://192.168.22.22:8123/kiosk-gene-desk/immich?kiosk";
        rotate = "90";
        wirelessInterface = config.genebean.kiosk-hardware.wirelessInterface;
      };
      kiosk-backups.enable = true;
      restic.enable = true;
    };
  };

  programs.zsh.history.path = "/tmp/zsh_history_gene"; # needed becaues of read only fs
}
