{ config, lib, pkgs, username, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "24.11";

  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
  ];

  environment.systemPackages = with pkgs; [
    wlr-randr
  ];

  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
  };

  networking = {
    firewall.enable = false;
    useNetworkd = true;
    wireless = {
      enable = true;
      networks = {
        # Home
        "Diagon Alley".pskRaw = "ext:psk_diagon_alley";
        # Public networks
        "Gallery Row-GuestWiFi" = {};
        "LocalTies Guest".pskRaw = "ext:psk_local_ties";
      };
      secretsFile = "${config.sops.secrets.wifi_creds.path}";
    };
  };

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  services = {
    cage = let
      kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
        WAYLAND_DISPLAY=wayland-0 wlr-randr --output HDMI-A-1
        /etc/profiles/per-user/gene/bin/chromium-browser
      '';
    in {
      enable = true;
      program = kioskProgram;
      user = "gene";
      environment = {
        WLR_LIBINPUT_NO_DEVICES = "1"; # boot up even if no mouse/keyboard connected
      };
    };
    prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "logind"
        "systemd"
        "network_route"
      ];
      disabledCollectors = [
        "textfile"
      ];
    };
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
      wifi_creds = {
        sopsFile = ../../common/secrets.yaml;
        restartUnits = [
          "wpa_supplicant.service"
        ];
      };
    };
  };

  systemd.services.cage-tty1 = {
    wants = [
      "wpa_supplicant.service"
      "network-online.target"
    ];
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "networkmanager" "wheel" ];
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvLaPTfG3r+bcbI6DV4l69UgJjnwmZNCQk79HXyf1Pt gene@rainbow-planet"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp42X5DZ713+bgbOO+GXROufUFdxWo7NjJbGQ285x3N gene.liverman@ltnglobal.com"
    ];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 90;
  };
}

