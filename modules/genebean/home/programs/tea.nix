{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.tea;
in
{
  options.genebean.programs.tea = {
    enable = lib.mkEnableOption "tea, the official Gitea/Forgejo CLI client";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.tea ];
  };
}
