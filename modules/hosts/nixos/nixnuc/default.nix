{ config, pkgs, username,  ... }: {
  imports = [
    ./hardware-configuration.nix
    ./containers/audiobookshelf.nix
    ./containers/nginx-proxy.nix
    ../../../system/common/linux/restic.nix
  ];

  system.stateVersion = "23.11";

  # Bootloader.
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs = {
      extraPools = [ "orico" ];
      forceImportRoot = false;
    };
  };

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    jellyfin
    jellyfin-ffmpeg
    jellyfin-web
    net-snmp
    nginx
    podman-compose
    podman-tui # status of containers in the terminal
    yt-dlp
  ];

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    ];
  };

  networking = {
    # Open ports in the firewall.
    firewall.allowedTCPPorts = [ 22 80 13378 ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # firewall.enable = false;

    hostId = "c5826b45"; # head -c4 /dev/urandom | od -A none -t x4

    useDHCP = false;
    networkmanager.enable = true;
    vlans = {
      vlan23 = { id = 23; interface = "eno1"; };
    };
    bridges = {
      br1-23 = { interfaces = [ "vlan23" ]; };
    };
    interfaces = {
      eno1.useDHCP = true;
      br1-23 = {
        useDHCP = false;
        # This enables the container attached to the bridge to be reachable
        ipv4.routes = [{ address = "192.168.23.21"; prefixLength = 32; }];
      };
    };
  };

  # Hardware Transcoding for Jellyfin
  nixpkgs.overlays = [
    (self: super: {
      # "vaapiIntel" is in some docs, but that is an alias
      # to intel-vaapi-driver as of 2023-05-31
      intel-vaapi-driver = super.intel-vaapi-driver.override {
        enableHybridCodec = true;
      };
    })
  ];

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.mtr.enable = true;

  # List services that you want to enable:
  services = {
    fwupd.enable = true;
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    lldpd.enable = true;
    nginx = {
      enable = true;
      virtualHosts."jellyfin" = {
        default = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];
        locations = {
          "= /" = {
            return = "302 http://$host/web/";
          };
          "/" = {
            proxyPass = "http://127.0.0.1:8096";
            recommendedProxySettings = true;
            extraConfig = "proxy_buffering off;";
          };
          "= /web/" = {
            proxyPass = "http://127.0.0.1:8096/web/index.html";
            recommendedProxySettings = true;
          };
          "/socket" = {
            proxyPass = "http://127.0.0.1:8096";
            recommendedProxySettings = true;
            proxyWebsockets = true;
          };
        };
      };
    };
    resolved.enable = true;
    restic.backups.daily.paths = [
      "/orico/jellyfin/data"
      "/orico/jellyfin/staging/downloaded-files"
      #"${config.users.users.${username}.home}/compose-files/tandoor"
    ];
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_key.path;
      extraUpFlags = [
        "--advertise-exit-node"
        "--operator=${username}"
        "--ssh"
        "--advertise-routes=192.168.20.0/22"
      ];
      useRoutingFeatures = "both";
    };
    zfs.autoScrub.enable = true;
  };

  sops = {
    age.keyFile = /home/${username}/.config/sops/age/keys.txt;
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_git_config = {
        owner = "${username}";
        path = "/home/${username}/.gitconfig-local";
      };
      local_private_env = {
        owner = "${username}";
        path = "/home/${username}/.private-env";
      };
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "podman" "networkmanager" "wheel" ];
  };

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;

  virtualisation.oci-containers.backend = "podman";

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;

    # Required for containers under podman-compose to be able to talk to each other.
    defaultNetwork.settings.dns_enabled = true;
  };
}
