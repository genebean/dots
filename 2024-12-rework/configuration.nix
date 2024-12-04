{ inputs, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "23.05";

  boot = {
    initrd.systemd = {
      enable = true;
      network.wait-online.enable = false; # Handled by NetworkManager
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot= {
        enable = true;
        consoleMode = "1";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    olm
  ];
}