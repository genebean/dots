{
  # Though it wouldn't seem to be this way,
  # This is used both in NixOS and Home Manager
  services = {
    flatpak = {
      enable = true;
      packages = [
        "com.cassidyjames.butler"
        "com.logseq.Logseq"
        "com.vivaldi.Vivaldi"
        "im.riot.Riot"
        "io.kopia.KopiaUI"
        "org.localsend.localsend_app"
        "org.gnome.Fractal"
        "org.signal.Signal"
        "org.telegram.desktop"
      ];
      uninstallUnmanaged = true;
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
  };
}
