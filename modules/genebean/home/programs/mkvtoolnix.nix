{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.mkvtoolnix;
in
{
  options.genebean.programs.mkvtoolnix = {
    enable = lib.mkEnableOption "MKVToolNix Matroska tools";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.mkvtoolnix ];
  };
}
