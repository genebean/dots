{
  config,
  genebeanLib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.ghostty;
in
{
  options.genebean.programs.ghostty = {
    enable = lib.mkEnableOption "Ghostty terminal";
    installViaHomebrew = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isDarwin;
    };
    installViaNix = lib.mkOption {
      type = lib.types.bool;
      default = genebeanLib.isNixOS;
    };
    enableSystemd = lib.mkOption {
      type = lib.types.bool;
      default = genebeanLib.isNixOS;
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/com.mitchellh.ghostty/config".text = ''
        # Ghostty configuration is managed by home-manager.
        # Settings are in modules/genebean/home/programs/ghostty.nix in the dots repo.
      '';
    };

    programs.ghostty = {
      enable = true;
      package = if cfg.installViaNix then pkgs.ghostty else null;
      enableZshIntegration = true;
      systemd.enable = cfg.enableSystemd;
      settings = {
        font-family = "Hack Nerd Font Mono";
        font-size = 14;
        background-opacity = 0.92;
        unfocused-split-opacity = 0.8;
        split-divider-color = "#ffbf00";
        window-padding-x = 5;
        window-padding-y = 5;
        window-padding-balance = true;
        background = "07042B";
        foreground = "E3E3EA";
        cursor-color = "FF7F7F";
        cursor-text = "07042B";
        selection-background = "7DF9FF";
        selection-foreground = "07042B";
        palette = [
          "0=#000000"
          "1=#E52222"
          "2=#55FF55"
          "3=#F0C040"
          "4=#C48DFF"
          "5=#FA2573"
          "6=#7DF9FF"
          "7=#F2F2F2"
          "8=#555555"
          "9=#FF5555"
          "10=#55FF55"
          "11=#FFFF55"
          "12=#6CB6FF"
          "13=#FF55FF"
          "14=#7DF9FF"
          "15=#FFFFFF"
        ];
        keybind = [
          "cmd+d=new_split:right"
          "cmd+shift+d=new_split:down"
          "super+d=new_split:right"
          "super+shift+d=new_split:down"
        ];
      };
    };
  };
}
