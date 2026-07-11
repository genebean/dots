{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.programs.kopiaui;
in
{
  options.genebean.programs.kopiaui = {
    enable = lib.mkEnableOption "KopiaUI backup browser";
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
        "io.kopia.KopiaUI"
      ];
    }
  );
}
