{ pkgs, username,  ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./post-install
  ];

  system.stateVersion = "24.05";

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a
    # EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  environment.systemPackages = with pkgs; [
    podman-tui # status of containers in the terminal
    podman-compose
  ];

  networking = {
    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      22   # ssh
      25   # SMTP (unencrypted)
      80   # http to local Nginx
      143  # imap
      443  # https to local Nginx
      465  # SMTP with TLS
      587  # SMTP with STARTTLS
      993  # imaps
      1883 # mqtt
      8333 # Bitcoin Core
      8448 # Matrix Synapse
      8883 # mqtt over tls
      9001 # mqtt websockets over tls
      9735 # LND
    ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # firewall.enable = false;

    hostId = "85d0e6cb"; # head -c4 /dev/urandom | od -A none -t x4

    networkmanager.enable = true;
  };

  programs.mtr.enable = true;

  services = {
    fail2ban.enable = true;
    logrotate.enable = true;
    ntopng = {
      enable = true;
      interfaces = [
        "enp1s0"
        "tailscale0"
      ];
    };
    openssh.settings = {
      # require public key authentication for better security
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
    };
    postgresqlBackup = {
      enable = true;
      backupAll = true;
      startAt = "*-*-* 23:00:00";
    };
    uptime-kuma = {
      enable = true;
      settings = {
        UPTIME_KUMA_HOST = "127.0.0.1";
        #UPTIME_KUMA_PORT = "3001";
      };
    };
  };

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      address = [
        "5.161.244.95/32"
        "2a01:4ff:f0:977c::1/64"
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxSBXdng/+esUXN/uLHQ0l9SgHS5EI9Z8UbqxLMNpK5 gene@newt"
    ];
  };
}
