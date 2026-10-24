{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./post-install
    inputs.private-flake.nixosModules.private.hetznix02
    ../../../shared/nixos/auditd.nix
    ../../../shared/nixos/crowdsec.nix
    ../../../shared/nixos/multiverse.nix
    ../../../shared/nixos/fail2ban-nginx.nix
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

    hostId = "89bbb3e6"; # head -c4 /dev/urandom | od -A none -t x4

    networkmanager.enable = false;
    useNetworkd = true;
  };

  programs.mtr.enable = true;

  services = {
    # sshd jail comes enabled by default from the fail2ban package itself;
    # nginx-http-auth/nginx-botsearch jails come from
    # ../../../shared/nixos/fail2ban-nginx.nix (imported above).
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
