{ inputs, pkgs, ... }: {
  # Settings just for personal machines go here

  imports = [
    "${inputs.nix-flatpak}/modules/home-manager.nix"
     ../common/linux/flatpaks.nix
  ];

  home.packages = with pkgs; [
    chirp
  ];
}
