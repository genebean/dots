{
  home.stateVersion = "23.11";

  genebean = {
    services = {
      restic = {
        enable = true;
        enablePruneJob = true;
      };

      tailscale = {
        advertiseExitNode = true;
        advertiseRoutes = [ "192.168.20.0/22" ];
        useRoutingFeatures = "both";
      };
    };
  };
}
