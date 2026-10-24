{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.slack;
in
{
  options.genebean.programs.slack = {
    enable = lib.mkEnableOption "Slack messaging";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    # pkgs.slack has no aarch64-linux source upstream (confirmed: throws
    # "Unsupported system" there) - narrower than isLinux for exactly that
    # reason, not a nixpkgs packaging gap.
    home.packages = [ pkgs.slack ];
  };
}
