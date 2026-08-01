{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.services.dnclient;
in
{
  options.genebean.services.dnclient = {
    enable = lib.mkEnableOption "dnclient managed Nebula VPN";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.dnclient ];

    systemd.services.dnclient = {
      description = "DNClient Nebula VPN";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.dnclient}/bin/dnclient run";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
