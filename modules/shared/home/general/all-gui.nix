{ pkgs, ... }:
{
  genebean = {
    programs = {
      askpass.enable = true;
      audacity.enable = true;
      element.enable = true;
      firefox.enable = true;
      ghostty.enable = true;
      gitkraken.enable = true;
      handbrake.enable = true;
      kopiaui.enable = true;
      libreoffice.enable = true;
      localsend.enable = true;
      logseq.enable = true;
      meld.enable = true;
      mkvtoolnix.enable = true;
      mumble.enable = true;
      nextcloud-client.enable = true;
      onepassword.enable = true;
      onlyoffice.enable = true;
      signal.enable = true;
      slack.enable = true;
      telegram.enable = true;
      transmission.enable = true;
      ungoogled-chromium.enable = true;
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
