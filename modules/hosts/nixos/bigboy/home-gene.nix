{ ... }:
{
  home.stateVersion = "24.05";
  imports = [
    ../../../shared/home/general/all-gui.nix
  ];

  genebean = {
    plasma.enable = true;
    programs = {
      askpass.enable = true;
      tilix.enable = true;
      vlc.enable = true;
      xfce4-terminal.enable = true;
    };
    services = {
      flatpak.enable = true;
    };
  };

}
