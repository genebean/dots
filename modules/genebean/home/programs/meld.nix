{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.meld;
in
{
  options.genebean.programs.meld = {
    enable = lib.mkEnableOption "Meld diff viewer";
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
      pkgs.meld
    ];
  };
}
