{ inputs, pkgs, ... }:
{
  system.stateVersion = 4;

  environment = {
    systemPackages = with pkgs; [
      chart-testing
      goreleaser
      inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default
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
      "puppetlabs/puppet"
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
      "boinc"
      "discord"
      "elgato-stream-deck"
      "google-drive"
      "gpg-suite"
      "kopiaui"
      "multipass"
      "mumble"
      "obs"
      "openvox8-agent"
      "openvox8-openbolt"
      "pdk"
      "podman-desktop"
      "qmk-toolbox"
      "raspberry-pi-imager"
      "thunderbird"
      "thunderbird@daily"
      "ungoogled-chromium"
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
      "Telegram" = 747648890;
      "WhatsApp Messenger" = 310633997;
      "Xcode" = 497799835;
    };
  };

  security.pam.services.sudo_local.enable = false;
}
