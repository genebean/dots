{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.angry-ip-scanner;
in
{
  options.genebean.programs.angry-ip-scanner = {
    enable = lib.mkEnableOption "Angry IP Scanner network scanner";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.angryipscanner ];
  };
}
