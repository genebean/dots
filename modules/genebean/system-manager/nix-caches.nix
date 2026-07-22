let
  caches = import ../data/nix-caches.nix;
in
{
  environment.etc."nix/nix.conf.d/genebean-caches.conf".text =
    builtins.concatStringsSep "\n" (
      map (s: "extra-substituters = ${s}") caches.substituters
      ++ map (k: "extra-trusted-public-keys = ${k}") caches.trustedPublicKeys
    )
    + "\n";

  # Restart nix-daemon whenever the cache config file changes so the new
  # substituters are picked up without requiring a manual intervention.
  systemd.paths.nix-daemon-reload = {
    wantedBy = [ "system-manager.target" ];
    pathConfig.PathChanged = "/etc/nix/nix.conf.d/genebean-caches.conf";
  };

  systemd.services.nix-daemon-reload = {
    description = "Restart nix-daemon after cache config change";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/usr/bin/systemctl restart nix-daemon.service";
    };
  };
}
