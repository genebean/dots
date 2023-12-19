{ inputs, config, hostname, pkgs, sops-nix, username,  ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "23.11";

  # Bootloader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  environment.systemPackages = with pkgs; [
    helix
    jellyfin
    jellyfin-ffmpeg
    jellyfin-web
    net-snmp
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
    firewall.allowedTCPPorts = [ 22 ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # firewall.enable = false;

    networkmanager.enable = true;
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
    tailscale = {
      extraUpFlags = [
        "--advertise-exit-node"
        "--operator ${username}"
        "--ssh"
      ];
    };
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
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
    packages = with pkgs; [
      docker-compose 
    ];
  };

  virtualisation.docker.enable = true;
}
