{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.plasma.enable {
    environment.systemPackages = with pkgs.kdePackages; [
      bluedevil
      bluez-qt
      ksshaskpass
      polkit-kde-agent-1
      xdg-desktop-portal-kde
    ];

    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    };
  };
}
