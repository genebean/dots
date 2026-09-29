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
    home.file.".claude/skills/hindsight-global-memory/SKILL.md".source =
      ./claude-code/hindsight-global-memory/SKILL.md;

    home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [ pkgs.claude-code ];
  };
}
