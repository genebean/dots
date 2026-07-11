{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.transmission;
in
{
  options.genebean.programs.transmission = {
    enable = lib.mkEnableOption "Transmission BitTorrent client";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.transmission_4-gtk ];
  };
}
