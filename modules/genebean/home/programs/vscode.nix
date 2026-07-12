{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.vscode;
in
{
  options.genebean.programs.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code";
  };

  config = lib.mkIf (cfg.enable && !pkgs.stdenv.isDarwin) {
    programs.vscode.enable = true;
  };
}
