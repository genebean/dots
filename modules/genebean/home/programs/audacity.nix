{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.audacity;
in
{
  options.genebean.programs.audacity = {
    enable = lib.mkEnableOption "Audacity audio editor";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.audacity ];
  };
}
