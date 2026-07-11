{
  config,
  genebeanLib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.element;
in
{
  options.genebean.programs.element = {
    enable = lib.mkEnableOption "Element Matrix client";
    linuxInstallMethod = lib.mkOption {
      type = lib.types.enum [
        "flatpak"
        "nixpkgs"
        "none"
      ];
      default = "flatpak";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      services.flatpak.packages = lib.mkIf (cfg.linuxInstallMethod == "flatpak") [
        "im.riot.Riot"
      ];
      home.packages = lib.mkIf (cfg.linuxInstallMethod == "nixpkgs") [
        pkgs.element-desktop
      ];
    }
  );
}
