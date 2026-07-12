{ lib, ... }:
{
  options.genebean.programs.firefox = {
    enable = lib.mkEnableOption "Firefox browser";
  };
}
