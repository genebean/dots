{
  lib,
  ...
}:
{
  options.genebean.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN";
    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "client";
      description = "Routing features to enable (client for desktops, both for exit nodes/routers)";
    };
    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
}
