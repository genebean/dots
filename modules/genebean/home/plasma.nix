{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.plasma;
in
{
  options.genebean.plasma = {
    enable = lib.mkEnableOption "KDE Plasma desktop";
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      programs.plasma = {
        enable = true;
        shortcuts = {
          kwin."Show Desktop" = [ ];
        };
      };
    }
  );
}
