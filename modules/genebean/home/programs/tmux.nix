{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.tmux;
in
{
  options.genebean.programs.tmux = {
    enable = lib.mkEnableOption "tmux terminal multiplexer";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      historyLimit = 100000;
      mouse = true;
      tmuxinator.enable = true;
      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        {
          plugin = dracula;
          extraConfig = ''
            set -g @dracula-show-battery false
            set -g @dracula-show-powerline true
            set -g @dracula-refresh-rate 10
          '';
        }
      ];
      extraConfig = ''
        set -g status-position top
      '';
    };
  };
}
