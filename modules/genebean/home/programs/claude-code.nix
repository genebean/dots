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

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [ pkgs.claude-code ];
  };
}
