{ pkgs, ... }:
{
  genebean = {
    programs = {
      askpass.enable = true;
      firefox.enable = true;
      ghostty.enable = true;
      onepassword.enable = true;
      vscode.enable = true;
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
