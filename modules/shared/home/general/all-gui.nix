{ pkgs, ... }:
{
  genebean = {
    programs = {
      askpass.enable = true;
      element.enable = true;
      firefox.enable = true;
      ghostty.enable = true;
      kopiaui.enable = true;
      libreoffice.enable = true;
      localsend.enable = true;
      logseq.enable = true;
      onepassword.enable = true;
      signal.enable = true;
      telegram.enable = true;
      vivaldi.enable = true;
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
