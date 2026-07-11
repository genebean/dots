{
  config,
  genebeanLib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.vivaldi;
in
{
  options.genebean.programs.vivaldi = {
    enable = lib.mkEnableOption "Vivaldi browser";
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
        "com.vivaldi.Vivaldi"
      ];
      home.packages = lib.mkIf (cfg.linuxInstallMethod == "nixpkgs") [
        pkgs.vivaldi
      ];
    }
  );
}
