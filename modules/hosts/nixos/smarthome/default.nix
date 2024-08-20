{ pkgs-unstable, username, ... }: {
  imports = [ # Include the results of the hardware scan.
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../../system/common/linux/restic.nix
  ];

  system.stateVersion = "24.05";

  boot.loader.grub.enable = true;

  networking = {
    firewall.allowedTCPPorts = [
      22   # ssh
    ];
    hostId = "aedb8615";
    useDHCP = false;
    networkmanager.enable = false;
    useNetworkd = true;
    interfaces.ens18.ipv4.addresses = [{
      address = "192.168.22.23";
      prefixLength = 24;
    }];
  };

  services = {
    esphome = {
      enable = true;
      package = pkgs-unstable.esphome;
      address = "0.0.0.0";
      openFirewall = true;
      port = 6052;
    };
    qemuGuest.enable = true;
    resolved.enable = true;
    restic.backups.daily.paths = [
      "/var/lib/esphome"
    ];
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "wheel" ];
    hashedPassword = 
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBjigwV0KnnaTnFmKjjvnULa5X+hvsy2FAlu+lUUY59f gene@rainbow-planet"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N gene.liverman@ltnglobal.com"
    ];
  };
}

