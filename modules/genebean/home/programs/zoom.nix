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

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    # zoom-us has no aarch64-linux build upstream (confirmed: pkgs.zoom-us
    # throws "not available on the requested hostPlatform" there) - this is
    # narrower than a plain isLinux check for exactly that reason, not just
    # a nixpkgs packaging gap.
    home.packages = lib.mkIf (cfg.linuxInstallMethod == "nixpkgs") [
      pkgs.zoom-us
    ];
  };
}
