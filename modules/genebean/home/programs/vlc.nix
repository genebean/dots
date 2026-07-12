{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.vlc;
  libbluray = pkgs.libbluray.override {
    withAACS = true;
    withBDplus = true;
    withJava = true;
  };
  vlc-with-decoding = pkgs.vlc.overrideAttrs (oldAttrs: {
    buildInputs = map (dep: if dep.pname or "" == "libbluray" then libbluray else dep) (
      oldAttrs.buildInputs or [ ]
    );
  });
in
{
  options.genebean.programs.vlc = {
    enable = lib.mkEnableOption "VLC media player with Blu-ray decoding support";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [
      pkgs.libbdplus
      vlc-with-decoding
    ];
  };
}
