{ config, pkgs, username, ... }:
  let
    libbluray = pkgs.libbluray.override {
      withAACS = true;
      withBDplus = true;
    };
    vlc-with-decoding = pkgs.vlc.override { inherit libbluray; };
  in
{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../common/linux/flatpaks.nix
    ../../common/linux/ripping.nix
  ];

  system.stateVersion = "24.11"; # Did you read the comment?

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    angryipscanner
    displaylink
    filezilla
    gitkraken
    kdePackages.ksshaskpass
    libreoffice
    meld
    mumble
    networkmanager-openvpn
    rclone
    rclone-browser
    slack
    tilix
    vivaldi
    vlc-with-decoding
    xorg.xf86videofbdev
    xfce.xfce4-terminal
    zoom-us
  ];

  hardware.pulseaudio.enable = false;
  
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

    ssh.askPassword = "ssh-askpass";

    # common programs that really should be in another file
    # required for setting to be picked up by xfce4-terminal
    xfconf.enable = true;
  };

  security.rtkit.enable = true;

  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    printing.enable = true; # Enable CUPS
    smartd.enable = true;
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
      local_git_config = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.gitconfig-local";
      };
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
    extraGroups = [ "networkmanager" "wheel" "dialout" "input" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };
}
