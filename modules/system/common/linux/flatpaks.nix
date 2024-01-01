
{ ... }: {
  services = {
    flatpak = {
      enable = true;
      packages = [
        "im.riot.Riot"
        "org.telegram.desktop"
      ];
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
  };
}
