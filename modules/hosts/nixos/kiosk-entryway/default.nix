{
  config,
  username,
  ...
}:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./monitoring.nix
    ../../../shared/nixos/restic.nix
  ];

  system.stateVersion = "24.11";

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
      enabledCollectors = [
        "logind"
        "systemd"
        "network_route"
      ];
      disabledCollectors = [
        "textfile"
      ];
    };
    smartd.enable = true;
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
}
