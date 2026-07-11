{ pkgs, ... }:
{
  genebean = {
    programs = {
      askpass.enable = true;
      ghostty.enable = true;
      wezterm.enable = true;
    };
  };

  home.packages = with pkgs; [
    esptool
  ];

  programs = {
    git.settings.aliases = {
      kraken = "!gitkraken -p $(cd \"\${1:-.}\" && git rev-parse --show-toplevel)";
    };
  };

}
