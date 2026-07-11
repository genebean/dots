{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.slack;
in
{
  options.genebean.programs.slack = {
    enable = lib.mkEnableOption "Slack messaging";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.slack ];
  };
}
