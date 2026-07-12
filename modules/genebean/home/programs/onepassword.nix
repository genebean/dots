{ lib, ... }:
{
  options.genebean.programs.onepassword = {
    enable = lib.mkEnableOption "1Password password manager";
  };
}
