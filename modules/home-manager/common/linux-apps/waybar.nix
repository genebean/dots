{ pkgs, ... }: {
  home.file = {
    ".config/waybar/config".source = ../../files/waybar/config;
    ".config/waybar/frappe.css".source = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "waybar";
      rev = "f74ab1eecf2dcaf22569b396eed53b2b2fbe8aff";
      hash = "sha256-WLJMA2X20E5PCPg0ZPtSop0bfmu+pLImP9t8A8V4QK8=";
    } + "/themes/frappe.css");
    ".config/waybar/style.css".source = ../../files/waybar/style.css;
  };

   programs = {
    # Using file in ../../files/waybar/ to configure waybar
    waybar.enable = true;
  };
}