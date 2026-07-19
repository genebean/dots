{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  system.stateVersion = 4;

  # Local aarch64-linux/x86_64-linux builder VM (Apple Virtualization
  # framework) so aarch64-linux builds like kiosk-gene-desk's don't have
  # to go over the network to hetznix02. Started/stopped manually via the
  # `linux-builder` wrapper below rather than always-on, since it's
  # only needed occasionally - KeepAlive/RunAtLoad would otherwise keep
  # it (and its 4 cores/6GB) running in the background permanently.
  # Its qcow2 disk (and anything already built on it) persists across
  # start/stop either way; it's only lost if nix.linux-builder.enable
  # is set back to false.
  launchd.daemons.linux-builder.serviceConfig = {
    KeepAlive = lib.mkForce false;
    RunAtLoad = lib.mkForce false;
  };

  nix.linux-builder = {
    enable = true;
    config = {
      virtualisation.cores = 4;
      virtualisation.darwin-builder.memorySize = 6 * 1024;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      chart-testing
      golangci-lint
      goreleaser
      inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.nixos-anywhere.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.viscosity-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
      kopia
      kubectx
      (writeShellScriptBin "linux-builder" ''
        set -euo pipefail
        case "''${1:-}" in
          start)
            sudo launchctl kickstart -k system/org.nixos.linux-builder
            ;;
          stop)
            sudo launchctl bootout system/org.nixos.linux-builder
            ;;
          status)
            sudo launchctl print system/org.nixos.linux-builder 2>&1 | grep -i state || echo "not loaded"
            ;;
          *)
            echo "usage: linux-builder start|stop|status" >&2
            exit 1
            ;;
        esac
      '')
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
