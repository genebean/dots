{
  home.stateVersion = "24.05";

  genebean = {
    services = {
      restic.enable = true;

      tailscale = {
        advertiseExitNode = true;
        useRoutingFeatures = "both";
      };
    };
  };
}
