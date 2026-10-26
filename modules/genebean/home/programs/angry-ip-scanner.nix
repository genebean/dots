{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.angry-ip-scanner;
in
{
  options.genebean.programs.angry-ip-scanner = {
    enable = lib.mkEnableOption "Angry IP Scanner network scanner";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    # pkgs.angryipscanner has no aarch64-linux build upstream - narrower
    # than isLinux for exactly that reason, not a nixpkgs packaging gap.
    home.packages = [ pkgs.angryipscanner ];
  };
}
