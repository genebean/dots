{ ... }:
{
  home.stateVersion = "24.05";
  imports = [
    ../../../shared/home/general/all-gui.nix
    ../../../shared/home/linux/apps/tilix.nix
    ../../../shared/home/linux/apps/xfce4-terminal.nix
  ];

  genebean = {
    plasma.enable = true;
    programs = {
      askpass.enable = true;
    };
  };

}
