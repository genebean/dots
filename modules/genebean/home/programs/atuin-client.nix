{ config, lib, ... }:
let
  cfg = config.genebean.programs.atuin-client;
in
{
  options.genebean.programs.atuin-client = {
    enable = lib.mkEnableOption "Atuin shell history client";
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      settings = {
        ctrl_n_shortcuts = true; # Use Ctrl-0 .. Ctrl-9 instead of Alt-0 .. Alt-9 UI shortcuts
        enter_accept = true; # press tab to edit command before running
        filter_mode_shell_up_key_binding = "host"; # or global, host, directory, etc
        sync_address = "https://atuin.home.technicalissues.us";
        sync_frequency = "15m";
      };
    };
  };
}
