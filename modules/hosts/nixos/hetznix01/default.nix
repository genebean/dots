{ inputs, pkgs, username,  ... }: {
  imports = [
    ../../common/linux/nixroutes.nix
    ./disk-config.nix
    ./hardware-configuration.nix
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
      9333 # Bitcoin Knots
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
      enable = false;
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

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "networkmanager" "wheel" ];
    linger = true;
  };
}
