{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.zoom;
in
{
  options.genebean.programs.zoom = {
    enable = lib.mkEnableOption "Zoom video conferencing";
    linuxInstallMethod = lib.mkOption {
      type = lib.types.enum [
        "nixpkgs"
        "none"
      ];
      default = "nixpkgs";
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = lib.mkIf (cfg.linuxInstallMethod == "nixpkgs") [
      pkgs.zoom-us
    ];
  };
}
