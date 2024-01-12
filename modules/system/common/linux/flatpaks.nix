
{ ... }: {
  services = {
    flatpak = {
      enable = true;
      packages = [
        "im.riot.Riot"
        "com.cassidyjames.butler"
        "org.signal.Signal"
        "org.telegram.desktop"
      ];
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
  };
}
