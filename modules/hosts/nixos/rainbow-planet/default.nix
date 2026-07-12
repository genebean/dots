{
  inputs,
  config,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../shared/linux/flatpaks.nix
    ../../../shared/nixos/ports.nix
    ../../../shared/nixos/ripping.nix
  ];

  system.stateVersion = "23.05";

  boot = {
    initrd.systemd = {
      enable = true;
      network.wait-online.enable = false; # Handled by NetworkManager
    };
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "1";
      };
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    # host specific apps
    brightnessctl
    butane
    caligula
    chirp
    cilium-cli
    displaylink
    go
    hubble
    hugo
    inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default
    kdePackages.kdenlive
    kubectl
    kubectx
    kubernetes-helm
    kubeseal
    mediawriter
    networkmanager-openvpn
    pavucontrol
    #ulauncher
    podman-compose
    podman-tui # status of containers in the terminal
    #quickemu
    rclone-browser
    rpi-imager
    rpiboot
    sparrow
    step-cli
    trezor-suite
    trezor-udev-rules
    virt-manager
    whalebird
    wmctrl

  ];

  networking = {
    networkmanager.enable = true;
    useNetworkd = true;
  };

  programs = {
    adb.enable = true;
    #hyprland.enable = true;
  };

  services = {
    bpftune.enable = true;
    dbus.implementation = "broker";
    desktopManager.cosmic = {
      enable = false;
      xwayland.enable = false;
    };
    displayManager.cosmic-greeter.enable = false;
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
    smartd.enable = true;
    thermald.enable = true;
  };

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  services.pulseaudio.enable = false;

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
    };
  };

  systemd.network.wait-online.enable = false; # Handled by NetworkManager

  users.extraGroups.vboxusers.members = [ "${username}" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [
      "adbusers"
      "dialout"
      "docker"
      "input"
      "networkmanager"
      "podman"
      "wheel"
    ];
    packages = with pkgs; [
      tailscale-systray
    ];
  };

  virtualisation = {
    containers.enable = true;
    docker = {
      enable = true;
      package = pkgs.docker;
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
