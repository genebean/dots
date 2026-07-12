{
  config,
  genebeanLib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.signal;
in
{
  options.genebean.programs.signal = {
    enable = lib.mkEnableOption "Signal messenger";
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
        "org.signal.Signal"
      ];
      home.packages = lib.mkIf (cfg.linuxInstallMethod == "nixpkgs") [
        pkgs.signal-desktop
      ];
    }
  );
}
