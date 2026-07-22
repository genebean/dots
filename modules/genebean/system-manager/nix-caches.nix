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
}
