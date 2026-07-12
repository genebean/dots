{
  config,
  genebeanLib,
  lib,
  ...
}:
let
  cfg = config.genebean.programs.discord;
in
{
  options.genebean.programs.discord = {
    enable = lib.mkEnableOption "Discord";
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (!genebeanLib.isDarwin) {
      services.flatpak.packages = [ "com.discordapp.Discord" ];
    }
  );
}
