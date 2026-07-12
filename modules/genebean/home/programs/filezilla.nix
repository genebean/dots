{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.filezilla;
in
{
  options.genebean.programs.filezilla = {
    enable = lib.mkEnableOption "FileZilla FTP client";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.filezilla ];
  };
}
