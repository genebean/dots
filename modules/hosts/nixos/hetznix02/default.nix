{
  inputs,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../../shared/nixos/nixroutes.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./post-install
    inputs.private-flake.nixosModules.private.hetznix02
  ];

  system.stateVersion = "24.05";

  boot = {
    loader.grub = {
      # no need to set devices, disko will add all devices that have a
      # EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
    tmp.cleanOnBoot = true;
  };

  environment.systemPackages = with pkgs; [
    # podman-tui # status of containers in the terminal
    # podman-compose
  ];

  networking = {
    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      22 # ssh
      80 # Nginx
      443 # Nginx
    ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # firewall.enable = false;

    hostId = "89bbb3e6"; # head -c4 /dev/urandom | od -A none -t x4

    networkmanager.enable = false;
    useNetworkd = true;
  };

  programs.mtr.enable = true;

  services = {
    fail2ban.enable = true;
    logrotate.enable = true;
    udev.extraRules = ''
      ATTR{address}=="96:00:03:ae:45:aa", NAME="eth0"
    '';
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    linger = true;
  };

  zramSwap.enable = true;
}
