{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.boinc;
in
{
  options.genebean.programs.boinc = {
    enable = lib.mkEnableOption "BOINC distributed computing client";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.boinc ];
  };
}
