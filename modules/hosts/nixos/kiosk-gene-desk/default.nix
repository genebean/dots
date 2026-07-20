{
  config,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./disko.nix
    ./persistence.nix
    ../../../shared/nixos/restic.nix
  ];

  system.stateVersion = "24.11";

  boot = {
    # Independent of the GUI's own rotation (kiosk.sh's `wlr-randr
    # --output HDMI-A-1 --transform 90`, which only affects the
    # Wayland/cage compositor output) - this is the text console (fbcon),
    # visible before/outside of cage. 0=normal, 1=90cw, 2=180, 3=270cw.
    kernelParams = [ "fbcon=rotate:3" ];
    loader.raspberry-pi = {
      enable = true;
      variant = "4";
      # bootloader defaults to "uboot" for variant 4
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "hetznix02.technicalissues.us";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
        ];
        sshUser = "gene";
        sshKey = "/root/.ssh/id_ed25519";
      }
    ];
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  # Not part of genebean.kiosk-hardware: nixpkgs.overlays helps construct
  # `pkgs` itself, so gating it behind a home-manager-sourced cfg.enable
  # check creates a genuine circular dependency (evaluating cfg.enable
  # pulls in pkgs, which depends on nixpkgs.overlays, which is what we're
  # trying to compute) - confirmed via a real "infinite recursion" eval
  # error when this was tried. Stays per-host, unconditional.
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  services = {
    prometheus.exporters.node = {
      enable = true;
      inherit (config.genebean.ports.node-exporter) port;
      enabledCollectors = [
        "logind"
        "systemd"
        "network_route"
      ];
      disabledCollectors = [
        "textfile"
      ];
    };
  };

  # Public half of the sops-provided host key below - not secret, so it
  # doesn't need to round-trip through /persist or sops.
  environment.etc."ssh/ssh_host_ed25519_key.pub".text =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSKkIHEABAkf/40QZTaJlrcoz1SmlG9nkQBxA/8HtGX root@kiosk-gene-desk\n";

  services.openssh.hostKeys = [
    {
      path = config.sops.secrets.ssh_host_ed25519_key.path;
      type = "ed25519";
    }
  ];

  sops = {
    # Points directly at /persist rather than the impermanence-bind-mounted
    # ~/.config/sops alias: sops-nix's setupSecrets activation script runs
    # during initrd (confirmed on real hardware), which is earlier than
    # impermanence can ever bind-mount an arbitrary path like this one -
    # only a fixed set of core system paths qualify for that early stage
    # (see nixos/lib/utils.nix's pathsNeededForBoot). /persist itself is
    # already mounted by then (neededForBoot = true), so pointing here
    # directly sidesteps the timing race entirely.
    #
    # Deliberately NOT under .config: scripts/prep-install-bootstrap.sh
    # pre-seeds this file via nixos-anywhere's --extra-files *before*
    # nixos-install's activation ever runs, and that copy step (running
    # as root) creates .config itself as root:root as a side effect -
    # confirmed on a real fresh install, where impermanence's directory
    # creation happily created .config/chromium under it but never got
    # the chance to fix .config's own ownership, since it already
    # existed by then. Worse, this can't be patched with a tmpfiles `z`
    # rule after the fact either - systemd-tmpfiles refuses with
    # "Detected unsafe path transition ... (owned by gene) -> ...
    # (owned by root)", a hardcoded symlink-attack safety check with no
    # override. A flat path with no shared ancestor with anything
    # impermanence creates sidesteps the whole problem.
    age.keyFile = "/persist${config.users.users.${username}.home}/.sops-age-key";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "ssh_private_key_gene_kiosk-gene-desk" = {
        sopsFile = ../../../shared/secrets.yaml;
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.ssh/id_ed25519";
        mode = "0600";
        # pubkey is already declared in private-flake's ssh-keys lib and
        # used for authorized_keys elsewhere; ssh derives it from the
        # private key at runtime, so we don't need to place it separately.
      };
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
      ssh_host_ed25519_key = {
        path = "/etc/ssh/ssh_host_ed25519_key";
        owner = "root";
        mode = "0600";
        restartUnits = [ "sshd.service" ];
      };
    };
  };
}
