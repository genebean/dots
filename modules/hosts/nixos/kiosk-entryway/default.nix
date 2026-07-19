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
    ./monitoring.nix
  ];

  system.stateVersion = "24.11";

  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
  ];

  fonts = {
    fontconfig = {
      enable = true;
      useEmbeddedBitmaps = true;
    };
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
    ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
  };

  networking = {
    firewall.enable = false;
    useNetworkd = true;
    wireless = {
      enable = true;
      # Specify the interface explicitly so wpa_supplicant doesn't try to
      # auto-detect via /sys/class/net, which is not mounted in the 26.05
      # hardening sandbox (RootDirectory=/run/wpa_supplicant).
      interfaces = [ "wlp3s0" ];
      secretsFile = "${config.sops.secrets.wifi_creds.path}";
    };
  };

  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  services = {
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
    smartd.enable = true;
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
          "wpa_supplicant-wlp3s0.service"
        ];
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

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 90;
  };
}
