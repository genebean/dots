
{ ... }: {
  services = {
    flatpak = {
      enable = true;
      packages = [
        "com.cassidyjames.butler"
        "com.logseq.Logseq"
        "com.vivaldi.Vivaldi"
        "im.riot.Riot"
        "io.kopia.KopiaUI"
        "org.gnome.Fractal"
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
