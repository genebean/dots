{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.obs;
in
{
  options.genebean.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.obs-studio ];
  };
}
