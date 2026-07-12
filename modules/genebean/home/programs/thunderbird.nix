{ lib, ... }:
{
  options.genebean.programs.thunderbird = {
    enable = lib.mkEnableOption "Thunderbird email client";
  };
}
