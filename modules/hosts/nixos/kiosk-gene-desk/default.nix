{
  inputs,
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    # SD card image
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ../../../shared/nixos/ports.nix
    ./read-only-root.nix
  ];

  system.stateVersion = "24.11";

  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
  ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    raspberrypifw
    ubootRaspberryPi4_64bit
    wlr-randr
  ];

  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
    raspberry-pi."4".fkms-3d.enable = true;
  };

  networking = {
    firewall.enable = false;
    useNetworkd = true;
    wireless = {
      enable = true;
      # Specify the interface explicitly so wpa_supplicant doesn't try to
      # auto-detect via /sys/class/net, which is not mounted in the 26.05
      # hardening sandbox (RootDirectory=/run/wpa_supplicant).
      interfaces = [ "wlan0" ];
      secretsFile = "${config.sops.secrets.wifi_creds.path}";
    };
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "hetznix02.technicalissues.us";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
        ];
        sshUser = "gene";
        sshKey = "/root/.ssh/id_ed25519";
      }
    ];
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  sdImage.compressImage = true;

  services = {
    cage =
      let
        kioskProgram = pkgs.writeShellScript "kiosk.sh" ''
          WAYLAND_DISPLAY=wayland-0 wlr-randr --output HDMI-A-1 --transform 90
          /etc/profiles/per-user/gene/bin/chromium-browser
        '';
      in
      {
        enable = true;
        program = kioskProgram;
        user = "gene";
        environment = {
          WLR_LIBINPUT_NO_DEVICES = "1"; # boot up even if no mouse/keyboard connected
        };
      };
    prometheus.exporters.node = {
      enable = true;
      inherit (config.dots.ports.node-exporter) port;
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
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
      wifi_creds = {
        sopsFile = ../../../shared/secrets.yaml;
        owner = "wpa_supplicant";
        restartUnits = [
          "wpa_supplicant-wlan0.service"
        ];
      };
    };
  };

  systemd.services.cage-tty1 = {
    wants = [
      "wpa_supplicant-wlan0.service"
      "network-online.target"
    ];
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

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 90;
  };
}
