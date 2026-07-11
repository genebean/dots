{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.programs.home-assistant-companion;
in
{
  options.genebean.programs.home-assistant-companion = {
    enable = lib.mkEnableOption "Home Assistant companion app";
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      services.flatpak.packages = [ "com.cassidyjames.butler" ];
    }
  );
}
