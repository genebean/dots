
{ ... }: {
  services = {
    flatpak = {
      enable = true;
      packages = [
        "im.riot.Riot"
      ];
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
  };
}
