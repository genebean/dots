{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.programs.fractal;
in
{
  options.genebean.programs.fractal = {
    enable = lib.mkEnableOption "Fractal Matrix client";
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      services.flatpak.packages = [ "org.gnome.Fractal" ];
    }
  );
}
