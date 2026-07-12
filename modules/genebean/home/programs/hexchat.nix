{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.hexchat;
in
{
  options.genebean.programs.hexchat = {
    enable = lib.mkEnableOption "HexChat IRC client";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    programs.hexchat.enable = true;
  };
}
