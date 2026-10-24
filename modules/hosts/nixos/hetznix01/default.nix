{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./ports.nix
    ./post-install
    ../../../shared/nixos/auditd.nix
    ../../../shared/nixos/crowdsec.nix
    ../../../shared/nixos/fail2ban-nginx.nix
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
      allowedTCPPorts = lib.pipe config.genebean.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "tcp"))
        (map (e: e.port))
      ];
      allowedUDPPorts = lib.pipe config.genebean.ports [
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
    fail2ban = {
      enable = true;
      # sshd jail comes enabled by default from the fail2ban package itself.
      # nginx-http-auth/nginx-botsearch jails come from
      # ../../../shared/nixos/fail2ban-nginx.nix (imported above). WordPress
      # already has its own dedicated jails (post-install/wordpress.nix).
      # These two cover the mail stack (private-flake's email.nix,
      # simple-nixos-mailserver - unit names confirmed via `nix eval` against
      # config.systemd.services, not guessed) which had zero jail coverage
      # despite fail2ban.enable already being true here.
      jails = {
        "postfix" = ''
          enabled      = true
          filter       = postfix
          backend      = systemd
          journalmatch = _SYSTEMD_UNIT=postfix.service
          maxretry     = 5
          findtime     = 600
          bantime      = 3600
        '';
        "dovecot" = ''
          enabled      = true
          filter       = dovecot
          backend      = systemd
          journalmatch = _SYSTEMD_UNIT=dovecot.service
          maxretry     = 5
          findtime     = 600
          bantime      = 3600
        '';
      };
    };
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
