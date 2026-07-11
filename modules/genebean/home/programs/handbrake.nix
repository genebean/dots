{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.handbrake;
in
{
  options.genebean.programs.handbrake = {
    enable = lib.mkEnableOption "HandBrake video transcoder";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.handbrake ];
  };
}
