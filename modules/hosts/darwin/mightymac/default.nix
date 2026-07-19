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

  security = {
    pam.services.sudo_local.enable = false;
    # nix-darwin has no wheelNeedsPassword-style toggle like NixOS
    # (security.sudo only exposes extraConfig/keepTerminfo), so this is
    # a raw sudoers rule - needed for deploy-rs's non-interactive sudo
    # activation over SSH, which would otherwise hang on a password
    # prompt with no way to answer it. Scoped to deploy-rs's own two
    # sudo command patterns rather than blanket NOPASSWD: ALL (confirmed
    # by reading deploy-rs's src/deploy.rs and its activate.custom
    # builder in flake.nix):
    #   1. `sudo -u root <closure>/activate-rs ...` - the actual
    #      activation/wait/revoke entrypoint. That single already-root
    #      process is what runs nix-darwin's own activation - including
    #      its Homebrew steps - so this one rule covers the whole flake
    #      switch, not just the non-Homebrew parts.
    #   2. `sudo -u root rm /tmp/deploy-rs-canary-<hash>` - a *separate*
    #      command deploy-rs's magic-rollback confirmation step runs
    #      after a successful activation, to tell the target "keep this
    #      generation, don't roll back". Missing this one still lets
    #      activation succeed but makes confirmation hang on a password
    #      prompt, which deploy-rs correctly treats as a failure and
    #      rolls back - confirmed on hardware. deploy-rs passes bare
    #      `rm`, not a full path, and sudo resolves that via the
    #      invoking user's own PATH (no secure_path override in macOS's
    #      default sudoers) - which for gene.liverman is the Nix-managed
    #      coreutils at /run/current-system/sw/bin/rm, not /bin/rm.
    #      That symlink's path is stable across generations (only its
    #      target changes), so it's safe to hardcode here.
    sudo.extraConfig = ''
      gene.liverman ALL=(root) NOPASSWD: /nix/store/*/activate-rs *
      gene.liverman ALL=(root) NOPASSWD: /run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*
    '';
  };
}
