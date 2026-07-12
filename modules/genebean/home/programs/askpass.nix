{
  lib,
  ...
}:
{
  options.genebean.programs.askpass = {
    enable = lib.mkEnableOption "SSH askpass helper";
  };
}
