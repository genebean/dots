{
  config,
  genebeanLib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.localsend;
in
{
  options.genebean.programs.localsend = {
    enable = lib.mkEnableOption "LocalSend file sharing";
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
        "org.localsend.localsend_app"
      ];
      home.packages = lib.mkIf (cfg.linuxInstallMethod == "nixpkgs") [
        pkgs.localsend
      ];
    }
  );
}
