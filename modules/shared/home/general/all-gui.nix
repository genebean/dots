{ pkgs, ... }:
{
  genebean = {
    programs = {
      askpass.enable = true;
      element.enable = true;
      firefox.enable = true;
      ghostty.enable = true;
      gitkraken.enable = true;
      kopiaui.enable = true;
      libreoffice.enable = true;
      localsend.enable = true;
      logseq.enable = true;
      meld.enable = true;
      onepassword.enable = true;
      signal.enable = true;
      slack.enable = true;
      telegram.enable = true;
      vivaldi.enable = true;
      vscode.enable = true;
      wezterm.enable = true;
      zoom.enable = true;
    };
  };

  home.packages = with pkgs; [
    esptool
  ];

}
