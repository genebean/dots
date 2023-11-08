{ config, pkgs, ... }: let
  user = "gene";
  hostname = "rainbow-planet";
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  system.stateVersion = "23.05";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.consoleMode = "1";

  networking = {
    hostName = "${hostname}";
    networkmanager.enable = true;
  };
  services.tailscale.enable = true;

  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services.xserver = {
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
  };

  programs.hyprland.enable = true;


  # Enable CUPS to print documents.
  services.printing.enable = true;

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [ "networkmanager" "wheel" "dialout" "input" ];
    packages = with pkgs; [
     tailscale-systray
    ];
  };

  environment.shells = with pkgs; [ bash zsh ];
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Well, this sucks, hopefully a fixed version is available soon...
  nixpkgs.config.permittedInsecurePackages = [
    "electron-21.4.4"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    boinc
    brightnessctl
    dconf2nix
    file
    firefox
    gnome.nautilus
    libreoffice
    meld
    neofetch
    pavucontrol
    polkit-kde-agent
    python3
    slack
    tailscale
    tilix
    ulauncher
    vivaldi
    whalebird
    wmctrl
    xfce.xfce4-terminal
    zoom-us
  ];

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      polkitPolicyOwners = [ "${user}" ];
    };
    # required for setting to be picked up by xfce4-terminal
    xfconf.enable = true;
  };

  # Used by Nautilus
  services.gvfs.enable = true;

  # Provides secret storage
  services.gnome.gnome-keyring.enable = true;

  services.boinc.enable = true;

  nix.settings = {
    allowed-users = [ "${user}" ];
    experimental-features = [
      "flakes"
      "nix-command"
    ];
  };

  fonts.fontDir.enable = false;
  fonts.packages = with pkgs; [
    font-awesome
    (nerdfonts.override {
      fonts = [
        "Hack"
        "SourceCodePro"
      ];
    })
  ];
}
