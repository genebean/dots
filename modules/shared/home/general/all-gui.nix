{ pkgs, ... }:
{
  genebean = {
    programs = {
      ghostty.enable = true;
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

  xdg.configFile."wezterm/wezterm.lua".source = ../../files/wezterm/wezterm.lua;
}
