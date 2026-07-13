{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.pidgin;
in
{
  options.genebean.programs.pidgin = {
    enable = lib.mkEnableOption "Pidgin IM client";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    programs.pidgin.enable = true;
  };
}
