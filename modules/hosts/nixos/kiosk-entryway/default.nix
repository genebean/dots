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
    ../../../shared/nixos/log-shipping.nix
  ];

  system.stateVersion = "24.11";

  # This host's own vector agent (log-shipping.nix) ships over this
  # host's own network - the public hostname's hairpin NAT path back
  # through the UniFi doesn't work reliably for on-prem callers, same
  # reasoning as nixnuc/id.home.technicalissues.us.
  networking.extraHosts = ''
    192.168.23.2 monitoring.home.technicalissues.us
  '';

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
