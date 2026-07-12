{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.sops;
in
{
  options.genebean.programs.sops = {
    enable = lib.mkEnableOption "sops secrets tooling";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      sops
      ssh-to-age
    ];
  };
}
