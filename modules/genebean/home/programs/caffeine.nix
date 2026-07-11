{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.programs.caffeine;
in
{
  options.genebean.programs.caffeine = {
    enable = lib.mkEnableOption "screen/sleep inhibitor";
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      services.flatpak.packages = [ "io.github.sigmasd.stimulator" ];
    }
  );
}
