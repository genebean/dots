{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.claude-code;
in
{
  options.genebean.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI coding assistant";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.claude-code ];
  };
}
