{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../../shared/nixos/ports.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./ports.nix
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
    firewall = {
      allowedTCPPorts = lib.pipe config.dots.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "tcp"))
        (map (e: e.port))
      ];
      allowedUDPPorts = lib.pipe config.dots.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "udp"))
        (map (e: e.port))
      ];
    };

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
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    linger = true;
  };
}
