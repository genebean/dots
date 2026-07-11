{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.gitkraken;
in
{
  options.genebean.programs.gitkraken = {
    enable = lib.mkEnableOption "GitKraken Git client";
    linuxInstallMethod = lib.mkOption {
      type = lib.types.enum [
        "nixpkgs"
        "none"
      ];
      default = "nixpkgs";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (pkgs.stdenv.isLinux && cfg.linuxInstallMethod == "nixpkgs") [
      pkgs.gitkraken
    ];

    programs.git.settings.aliases.kraken =
      "!gitkraken -p $(cd \"\${1:-.}\" && git rev-parse --show-toplevel)";
  };
}
