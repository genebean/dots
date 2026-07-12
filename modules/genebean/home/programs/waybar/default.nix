{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.waybar;
in
{
  options.genebean.programs.waybar = {
    enable = lib.mkEnableOption "Waybar status bar";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.file = {
      ".config/waybar/config".source = ./config;
      ".config/waybar/frappe.css".source =
        pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "waybar";
          rev = "f74ab1eecf2dcaf22569b396eed53b2b2fbe8aff";
          hash = "sha256-WLJMA2X20E5PCPg0ZPtSop0bfmu+pLImP9t8A8V4QK8=";
        }
        + "/themes/frappe.css";
      ".config/waybar/style.css".source = ./style.css;
    };

    programs.waybar.enable = true;
  };
}
