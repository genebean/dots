{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.powershell;
in
{
  options.genebean.programs.powershell = {
    enable = lib.mkEnableOption "PowerShell";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.powershell ];
      file = {
        ".config/powershell/Microsoft.PowerShell_profile.ps1".source = ./Microsoft.PowerShell_profile.ps1;
        ".config/powershell/Microsoft.VSCode_profile.ps1".source = ./Microsoft.PowerShell_profile.ps1;
      };
    };
  };
}
