{ inputs, lib, pkgs, username, ... }: {
  imports = [
    # SD card image
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  system.stateVersion = "24.11";

  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
  ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  hardware.enableRedistributableFirmware = true;

  networking.wireless = {
    enable = true;
    networks = {
      # Public networks
      "Gallery Row-GuestWiFi" = {};
      "LocalTies Guest" = {
        psk = "DrinkLocal!";
      };
    };
  };

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  services = {
    cage = {
      enable = true;
      program = "${pkgs.chromium}/bin/chromium-browser";
    };
  };

  sdImage.compressImage = false;

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
}

