# genebean.services.flatpak works in both NixOS and Home Manager contexts:
# the HM side (here) manages per-user packages and auto-update settings;
# the NixOS side enables the system service.
{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.services.flatpak;
in
{
  options.genebean.services.flatpak = {
    enable = lib.mkEnableOption "Flatpak package manager";
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      services.flatpak = {
        enable = true;
        uninstallUnmanaged = true;
        update.auto = {
          enable = true;
          onCalendar = "daily";
        };
      };
    }
  );
}
