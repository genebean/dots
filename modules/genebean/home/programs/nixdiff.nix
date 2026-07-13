{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.nixdiff;
in
{
  options.genebean.programs.nixdiff = {
    enable = lib.mkEnableOption "nixdiff system diff tool";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nixdiff ];
  };
}
