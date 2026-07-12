{
  config,
  genebeanLib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.ungoogled-chromium;
in
{
  options.genebean.programs.ungoogled-chromium = {
    enable = lib.mkEnableOption "Ungoogled Chromium browser";
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
        "io.github.ungoogled_software.ungoogled_chromium"
      ];
      home.packages = lib.mkIf (cfg.linuxInstallMethod == "nixpkgs") [
        pkgs.ungoogled-chromium
      ];
    }
  );
}
