{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.diff;
in
{
  options.genebean.programs.diff = {
    enable = lib.mkEnableOption "diff tools (colordiff, diff-so-fancy)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.colordiff ];

    programs = {
      diff-so-fancy = {
        enable = true;
        enableGitIntegration = true;
      };

      zsh.initContent = ''
        function svndiffless() {
          svn diff "$@" |diff-so-fancy |less -R
        }

        function svndiffless-nows() {
          svn diff -x -w "$@" |diff-so-fancy |less -R
        }
      '';
    };
  };
}
