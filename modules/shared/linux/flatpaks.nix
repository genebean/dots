{
  # Though it wouldn't seem to be this way,
  # This is used both in NixOS and Home Manager
  services = {
    flatpak = {
      enable = true;
      packages = [
        "com.cassidyjames.butler"
        "io.kopia.KopiaUI"
        "io.github.sigmasd.stimulator"
        "io.github.ungoogled_software.ungoogled_chromium"
        "org.localsend.localsend_app"
        "org.gnome.Fractal"
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
