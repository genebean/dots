{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.programs.onlyoffice;
in
{
  options.genebean.programs.onlyoffice = {
    enable = lib.mkEnableOption "OnlyOffice document suite";
    linuxInstallMethod = lib.mkOption {
      type = lib.types.enum [
        "flatpak"
        "none"
      ];
      default = "flatpak";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      services.flatpak.packages = lib.mkIf (cfg.linuxInstallMethod == "flatpak") [
        "org.onlyoffice.desktopeditors"
      ];
    }
  );
}
