{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.mumble;
in
{
  options.genebean.programs.mumble = {
    enable = lib.mkEnableOption "Mumble VoIP client";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.mumble ];
  };
}
