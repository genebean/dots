{ lib, pkgs, ... }: with lib.hm.gvariant; {

  dconf.settings = {
    "com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d" = {
      background-color = "#272822";
      background-transparency-percent = 10;
      badge-color-set = false;
      bold-color-set = false;
      cursor-colors-set = false;
      font = "Hack Nerd Font Mono 12";
      foreground-color = "#F8F8F2";
      highlight-colors-set = false;
      palette = [ "#272822" "#F92672" "#A6E22E" "#F4BF75" "#66D9EF" "#AE81FF" "#A1EFE4" "#F8F8F2" "#75715E" "#F92672" "#A6E22E" "#F4BF75" "#66D9EF" "#AE81FF" "#A1EFE4" "#F9F8F5" ];
      use-system-font = false;
      use-theme-colors = false;
      visible-name = "Default";
    };

  };

  home.file = {
    ".config/tilix/schemes/Beanbag-Mathias.json".source = ../../files/tilix/Beanbag-Mathias.json;
    ".config/tilix/schemes/Catppuccin-Frappe.json".source = (pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "tilix";
      rev = "3fd05e03419321f2f2a6aad6da733b28be1765ef";
      hash = "sha256-SI7QxQ+WBHzeuXbTye+s8pi4tDVZOV4Aa33mRYO276k=";
    } + "/src/Catppuccin-Frappe.json");
  };
}