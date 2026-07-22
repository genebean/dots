{ username, ... }:
{
  environment.etc."nix/nix.custom.conf".text = ''
    trusted-users = root ${username}

    # Add an include line here for each genebean system-manager module that
    # writes a file under /etc/nix/nix.conf.d/ so Determinate Nix picks it up.
    include /etc/nix/nix.conf.d/genebean-caches.conf
  '';
}
