{
  # Though it wouldn't seem to be this way,
  # This is used both in NixOS and Home Manager
  services = {
    flatpak = {
      enable = true;
      packages = [
        "com.cassidyjames.butler"
      ];
      uninstallUnmanaged = true;
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
  };
}
