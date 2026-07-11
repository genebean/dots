{
  config,
  pkgs,
  username,
  ...
}:
let
  libbluray = pkgs.libbluray.override {
    withAACS = true;
    withBDplus = true;
    withJava = true;
  };
  vlc-with-decoding = pkgs.vlc.overrideAttrs (oldAttrs: {
    buildInputs = map (dep: if dep.pname or "" == "libbluray" then libbluray else dep) (
      oldAttrs.buildInputs or [ ]
    );
  });
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../../shared/linux/flatpaks.nix
    ../../../shared/nixos/ports.nix
    ../../../shared/nixos/ripping.nix
  ];

  system.stateVersion = "24.11"; # Did you read the comment?

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  environment.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    #angryipscanner
    displaylink
    filezilla
    gitkraken
    libbdplus
    libreoffice
    meld
    mumble
    networkmanager-openvpn
    rclone-browser
    slack
    tilix
    vivaldi
    vlc-with-decoding
    xf86-video-fbdev
    xfce4-terminal
    zoom-us
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  networking.networkmanager.enable = true;

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      polkitPolicyOwners = [ "${username}" ];
    };

    firefox.enable = true;

    java = {
      enable = true; # Needed for some Blu-ray disk menus
      package = pkgs.jdk17;
    };

    kdeconnect.enable = true;

    # common programs that really should be in another file
    # required for setting to be picked up by xfce4-terminal
    xfconf.enable = true;
  };

  security.rtkit.enable = true;

  services = {
    fstrim.enable = true;
    fwupd.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    printing.enable = true; # Enable CUPS
    pulseaudio.enable = false;
    smartd.enable = true;
    thermald.enable = true;
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
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
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = "Gene Liverman";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "input"
    ];
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

}
