{ pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../../system/common/linux/flatpaks.nix
  ];

  system.stateVersion = "23.05";

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot= {
      enable = true;
      consoleMode = "1";
    };
  };

  environment.systemPackages = with pkgs; [
    # host specific apps
    boinc
    brightnessctl
    gnome.gnome-tweaks
    gnome.nautilus
    gnomeExtensions.dash-to-panel
    gnomeExtensions.tailscale-qs
    pavucontrol
    polkit-kde-agent
    ulauncher
    whalebird
    wmctrl

    # common gui apps that really should be in another file
    angryipscanner
    firefox
    gitkraken
    libreoffice
    meld
    slack
    tilix
    vivaldi
    xfce.xfce4-terminal
    zoom-us
  ];

  networking = {
    networkmanager.enable = true;
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      polkitPolicyOwners = [ "${username}" ];
    };
    hyprland.enable = true;

    # common programs that really should be in another file
    # required for setting to be picked up by xfce4-terminal
    xfconf.enable = true;
  };

  services = {
    boinc.enable = true;
    fwupd.enable = true;
    gnome.gnome-keyring.enable = true; # Provides secret storage
    gvfs.enable = true; # Used by Nautilus
    printing.enable = true; # Enable CUPS
    tailscale = {
      extraUpFlags = [
        "--operator"
        "${username}"
        "--ssh"
      ];
    };
    xserver = {
      enable = true;    # Enable the X11 windowing system.

      # Configure keymap in X11
      layout = "us";
      xkbVariant = "";

      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
      };
      desktopManager.gnome.enable = true;
    };
  };

  # Enable sound with pipewire.
  sound.enable = true;
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "networkmanager" "wheel" "dialout" "input" ];
    packages = with pkgs; [
      tailscale-systray
    ];
  };
}
