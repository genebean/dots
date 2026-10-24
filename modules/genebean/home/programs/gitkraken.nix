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
    # pkgs.gitkraken has no aarch64-linux build upstream - narrower than
    # isLinux for exactly that reason, not a nixpkgs packaging gap.
    home.packages =
      lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux" && cfg.linuxInstallMethod == "nixpkgs")
        [
          pkgs.gitkraken
        ];

    programs.git.settings.aliases.kraken =
      "!gitkraken -p $(cd \"\${1:-.}\" && git rev-parse --show-toplevel)";
  };
}
