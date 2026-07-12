{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.tailscale;
in
{
  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_key.path;
      extraUpFlags =
        lib.optional cfg.advertiseExitNode "--advertise-exit-node"
        ++ [
          "--operator"
          username
          "--ssh"
        ]
        ++ lib.optionals (cfg.advertiseRoutes != [ ]) [
          "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
        ];
      inherit (cfg) useRoutingFeatures;
    };

    sops.secrets.tailscale_key = {
      restartUnits = [ "tailscaled-autoconnect.service" ];
    };
  };
}
