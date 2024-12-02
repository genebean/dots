{ config, pkgs, username, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../../system/common/linux/restic.nix
  ];

  system.stateVersion = "24.05";

  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
      mirroredBoots = [
        {
          devices = ["/dev/disk/by-uuid/02A5-6FCC"];
          path = "/boot";
        }
        {
          devices = ["/dev/disk/by-uuid/02F1-B12D"];
          path = "/boot-fallback";
        }
      ];
    };
    supportedFilesystems = ["zfs"];
    zfs = {
      extraPools = [ "storage" ];
      forceImportRoot = false;
    };
  };

  environment.systemPackages = with pkgs; [
    net-snmp
  ];

  networking = {
    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      22 # ssh
    ];

    hostId = "da074317"; # head -c4 /dev/urandom | od -A none -t x4
    hostName = "nixnas1";

    networkmanager.enable = false;
    useNetworkd = true;
  };

  programs.mtr.enable = true;
  services = {
    fwupd.enable = true;
    lldpd.enable = true;
    resolved.enable = true;
    restic.backups.daily.paths = [
      # "/storage/foo"
    ];
    zfs.autoScrub.enable = true;
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_git_config = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.gitconfig-local";
      };
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
    };
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "10-bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer2+3";
        };
      };
    };
    networks = {
      "30-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.Bond = "bond0";
      };
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        networkConfig.Bond = "bond0";
      };
      "40-bond0" = {
        matchConfig.Name = "bond0";
        linkConfig = {
          RequiredForOnline = "carrier";
        };
        networkConfig = {
          DHCP = "yes";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
        };
      };
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N gene.liverman@ltnglobal.com"
    ];
  };
}
