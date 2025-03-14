{ inputs, config, pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../common/linux/flatpaks.nix
    ../../common/linux/ripping.nix
  ];

  system.stateVersion = "23.05";

  boot = {
    initrd.systemd = {
      enable = true;
      network.wait-online.enable = false; # Handled by NetworkManager
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot= {
        enable = true;
        consoleMode = "1";
      };
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    # host specific apps
    boinc
    brightnessctl
    butane
    caligula
    cilium-cli
    displaylink
    filezilla
    go
    hubble
    hugo
    inputs.flox.packages.${pkgs.system}.default
    kdePackages.kdenlive
    kubectl
    kubectx
    kubernetes-helm
    kubeseal
    mediawriter
    mumble
    networkmanager-openvpn
    nodejs
    pavucontrol
    polkit-kde-agent
    #ulauncher
    podman-compose
    podman-tui # status of containers in the terminal
    #quickemu
    rclone
    rclone-browser
    rpi-imager
    sparrow
    step-cli
    trezor-suite
    trezor-udev-rules
    virt-manager
    vlc
    whalebird
    wmctrl

    # common gui apps that really should be in another file
    angryipscanner
    gitkraken
    libreoffice
    meld
    slack
    tilix
    xfce.xfce4-terminal
    zoom-us
  ];

  networking = {
    networkmanager.enable = true;
    useNetworkd = true;
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      polkitPolicyOwners = [ "${username}" ];
    };
    firefox.enable = true;
    #hyprland.enable = true;

    ssh.askPassword = "ssh-askpass";

    # common programs that really should be in another file
    # required for setting to be picked up by xfce4-terminal
    xfconf.enable = true;
  };

  services = {
    boinc.enable = true;
    dbus.implementation = "broker";
    desktopManager.cosmic.enable = true;
    desktopManager.cosmic.xwayland.enable = false;
    desktopManager.plasma6.enable = true;
    displayManager.cosmic-greeter.enable = true;
    displayManager.sddm = {
      enable = false;
      wayland.enable = true;
    };
    flatpak = {
      enable = true;
      packages = [
        "com.blockstream.Green"
      ];
    };
    fstrim.enable = true;
    fwupd.enable = true;
    irqbalance.enable = true;
    printing.enable = true; # Enable CUPS
    resolved.enable = true;
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_key.path;
      extraUpFlags = [
        "--operator"
        "${username}"
        "--ssh"
      ];
      useRoutingFeatures = "client";
    };
    thermald.enable = true;
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
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
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  };

  systemd.network.wait-online.enable = false; # Handled by NetworkManager

  users.extraGroups.vboxusers.members = [ "${username}" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "dialout" "docker" "input" "networkmanager" "podman" "wheel" ];
    packages = with pkgs; [
      tailscale-systray
    ];
  };

  virtualisation = {
    containers.enable = true;
    docker = {
      enable = true;
      package = pkgs.docker_26;
    };
    libvirtd = {
      enable = true;
      qemu.package = pkgs.qemu_kvm;
    };
    podman = {
      enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings.dns_enabled = true;
      # dockerCompat = true;
    };
    virtualbox.host.enable = true;
  };
}
