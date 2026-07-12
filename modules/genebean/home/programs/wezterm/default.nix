{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.wezterm;
in
{
  options.genebean.programs.wezterm = {
    enable = lib.mkEnableOption "WezTerm terminal";
    installViaHomebrew = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isDarwin;
    };
    installViaNix = lib.mkOption {
      type = lib.types.bool;
      default = !pkgs.stdenv.isDarwin;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.installViaHomebrew {
        xdg.configFile."wezterm/wezterm.lua".text = builtins.readFile ./wezterm.lua;
      })
      (lib.mkIf cfg.installViaNix {
        programs.wezterm = {
          enable = true;
          package = pkgs.wezterm;
          extraConfig = builtins.readFile ./wezterm.lua;
        };
      })
    ]
  );
}
