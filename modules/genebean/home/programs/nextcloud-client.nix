{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.nextcloud-client;
in
{
  options.genebean.programs.nextcloud-client = {
    enable = lib.mkEnableOption "Nextcloud desktop client";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.nextcloud-client ];
  };
}
