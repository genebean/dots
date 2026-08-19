{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.genebean.sample;
in {
  imports = [
    # paths of other modules
  ];

  options.genebean.sample = {
    enable = mkEnableOption "Enable the genebean sample module";

    foo = mkOption {
      type = types.str;
      default = "defaultFoo";
      description = "An example string option for the genebean sample module.";
    };
  };

  config = mkIf cfg.enable {
    # configuration settings when enabled
    genebean.sample = {
      # option definitions
    };
  };
}
