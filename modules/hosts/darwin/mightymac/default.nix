{ inputs, pkgs, ... }:
{
  system.stateVersion = 4;

  environment = {
    systemPackages = with pkgs; [
      chart-testing
      golangci-lint
      goreleaser
      inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.viscosity-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
      kopia
      kubectx
      #reposurgeon # Nix is a major version behind brew
      rpiboot
      step-cli
      terraformer
    ];
  };

  homebrew = {
    taps = [
      "hashicorp/tap"
      "openvoxproject/openvox"
      "wouterdebie/repo"
    ];
    brews = [
      "adr-tools"
      "awscli"
      "gnupg"
      "i2cssh"
      "lima"
      "opentofu"
      "pinentry-mac"
      #"podman" # this version is missing libkrun. Use installer at https://github.com/containers/podman/releases instead
      "reposurgeon"
      "terraform-docs"
    ];
    casks = [
      "antigravity"
      "elgato-stream-deck"
      "google-drive"
      "gpg-suite"
      "multipass"
      "obs"
      "openvox8-agent"
      "openvox8-openbolt"
      "podman-desktop"
      "qmk-toolbox"
      "raspberry-pi-imager"
      "thunderbird@daily"
      #"utm"
      # "vagrant"
      "vial"
      #"whalebird"
    ];
    masApps = {
      #"FluffyChat" = 1551469600;
      "HomeCam" = 1292995895;
      "Keeper Password Manager" = 414781829;
      #"MEATER® Smart Meat Thermometer" = 1157416022;
      "MeetingBar" = 1532419400;
      "Meshtastic" = 1586432531;
      "Messenger" = 1480068668;
      "Microsoft Remote Desktop" = 1295203466;
      "WhatsApp Messenger" = 310633997;
      "Xcode" = 497799835;
    };
  };

  nix-homebrew = {
    trust = {
      taps = [
        "hashicorp/tap"
        "openvoxproject/openvox"
        "wouterdebie/repo"
      ];
    };
  };

  security.pam.services.sudo_local.enable = false;
}
