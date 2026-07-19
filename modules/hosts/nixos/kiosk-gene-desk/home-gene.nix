{
  home.stateVersion = "24.11";

  genebean.services = {
    chromium-kiosk = {
      enable = true;
      dashboardUrl = "http://192.168.22.22:8123/kiosk-gene-desk/immich?kiosk";
      rotate = "90";
    };
    tailscale.enable = true;
  };

  programs.zsh.history.path = "/tmp/zsh_history_gene"; # needed becaues of read only fs

}
