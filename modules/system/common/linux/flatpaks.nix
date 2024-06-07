
{ ... }: {
  services = {
    flatpak = {
      enable = true;
      packages = [
        "im.riot.Riot"
        "com.cassidyjames.butler"
        "com.logseq.Logseq"
        "com.vivaldi.Vivaldi"
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
