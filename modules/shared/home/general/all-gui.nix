{ pkgs, ... }:
{
  genebean = {
    programs = {
      angry-ip-scanner.enable = true;
      askpass.enable = true;
      boinc.enable = true;
      caffeine.enable = true;
      audacity.enable = true;
      discord.enable = true;
      element.enable = true;
      filezilla.enable = true;
      firefox.enable = true;
      fractal.enable = true;
      ghostty.enable = true;
      gitkraken.enable = true;
      handbrake.enable = true;
      home-assistant-companion.enable = true;
      kopiaui.enable = true;
      libreoffice.enable = true;
      localsend.enable = true;
      logseq.enable = true;
      meld.enable = true;
      mkvtoolnix.enable = true;
      mqtt-explorer.enable = true;
      mumble.enable = true;
      nextcloud-client.enable = true;
      obs.enable = true;
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
