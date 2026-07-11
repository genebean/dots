{
  home.stateVersion = "24.05";

  genebean = {
    services = {
      tailscale = {
        advertiseExitNode = true;
        useRoutingFeatures = "both";
      };
    };
  };
}
