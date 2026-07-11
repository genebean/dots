{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.mqtt-explorer;
in
{
  options.genebean.programs.mqtt-explorer = {
    enable = lib.mkEnableOption "MQTT Explorer";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.mqtt-explorer ];
  };
}
