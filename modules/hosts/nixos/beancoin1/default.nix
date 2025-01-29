{ inputs, config, pkgs, username, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../common/linux/restic.nix

    # Optional:
    # Import the secure-node preset, an opinionated config to enhance security
    # and privacy.
    #
    #(inputs.nix-bitcoin + "/modules/presets/secure-node.nix")
  ];

  system.stateVersion = "24.11";

  # The nix-bitcoin release version that your config is compatible with.
  # When upgrading to a backwards-incompatible release, nix-bitcoin will display an
  # an error and provide instructions for migrating your config to the new release.
  nix-bitcoin.configVersion = "0.0.85";

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
      config.services.bitcoind.port
      config.services.bitcoind.rpc.port
      config.services.electrs.port
      config.services.mempool.frontend.port
    ];

    hostId = "da074317"; # head -c4 /dev/urandom | od -A none -t x4
    hostName = "beancoin1";

    networkmanager.enable = false;
    useNetworkd = true;
  };

  nix-bitcoin = {
    # Automatically generate all secrets required by services.
    # The secrets are stored in /etc/nix-bitcoin-secrets
    generateSecrets = true;

    nodeinfo.enable = true;
    onionAddresses.access.${username} = [
      "bitcoind"
      "lnd"
    ];

    # When using nix-bitcoin as part of a larger NixOS configuration, set the following to enable
    # interactive access to nix-bitcoin features (like bitcoin-cli) for your system's main user
    operator = {
      enable = true;
      name = "${username}";
    };

    # Set this to accounce the onion service address to peers.
    # The onion service allows accepting incoming connections via Tor.
    onionServices = {
      bitcoind.public = true;
      lnd.public = true;
    };
  };

  programs.mtr.enable = true;

  services = {
    # Set this to enable nix-bitcoin's own backup service. By default, it
    # uses duplicity to incrementally back up all important files in /var/lib to
    # /var/lib/localBackups once a day.
    backups.enable = true;
    bitcoind = {
      enable = true;
      address = "0.0.0.0";
      dataDir = "/storage/bitcoin";
      # discover = true;
      # getPublicAddressCmd = "";
      i2p = true;
      listen = true;
      rpc = {
        address = "0.0.0.0";
        allowip = [
          "192.168.20.0/24"
          "192.168.25.0/24"
        ];
      };
      tor = {
        # If you're using the `secure-node.nix` template, set this to allow non-Tor connections to bitcoind
        enforce = false;
        # Also set this if bitcoind should not use Tor for outgoing peer connections
        proxy = false;
      };
      extraConfig = ''
        bind=::
      '';
    };
    electrs = {
      address = "0.0.0.0"; # Listen to connections on all interfaces
      tor.enforce = false; # Set this if you're using the `secure-node.nix` template
    };
    lightning-loop.enable = true;
    lldpd.enable = true;
    lnd ={
      enable = true;
      lndconnect = {
        enable = true;
        onion = true;
      };
    };
    mempool = {
      enable = true;
      electrumServer = "electrs";
      frontend = {
        enable = true;
        address = "0.0.0.0";
        port = 80;
      };
    };
    resolved.enable = true;
    restic.backups.daily.paths = [
      # "/storage/foo"
    ];
    tailscale = {
      enable = true;
      extraUpFlags = [
        "--operator"
        "${username}"
        "--ssh"
      ];
      useRoutingFeatures = "both";
    };
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvLaPTfG3r+bcbI6DV4l69UgJjnwmZNCQk79HXyf1Pt gene@rainbow-planet"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N gene.liverman@ltnglobal.com"
    ];
  };
}
