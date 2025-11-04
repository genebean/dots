{ pkgs, username,  ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./post-install
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
      22   # ssh
      80   # Nginx
      443  # Nginx
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

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      address = [
        "195.201.224.89/32"
        "2a01:4f8:1c1e:aa68::1/64"
        "fe80::9400:3ff:feae:45aa/64"
      ];
      dns = [
        "185.12.64.1"
        "185.12.64.2"
        "2a01:4ff:ff00::add:1"
        "2a01:4ff:ff00::add:2"
      ];
      routes = [
        { Destination = "172.31.1.1"; }
        { Gateway = "172.31.1.1"; GatewayOnLink = true; }
        { Gateway = "fe80::1"; }
      ];
      # make the routes on this interface a dependency for network-online.target
      linkConfig.RequiredForOnline = "routable";
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "networkmanager" "wheel" ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvLaPTfG3r+bcbI6DV4l69UgJjnwmZNCQk79HXyf1Pt gene@rainbow-planet"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N gene.liverman@ltnglobal.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyYpMcbTCpDtP7wUcXnfFXvekPL/tz/k2Q3kCZwfGwZ gene@kiosk-gene-desk"
    ];
  };

  zramSwap.enable = true;
}
