let
  caches = import ../data/nix-caches.nix;
in
{
  nix.settings = {
    extra-substituters = caches.substituters;
    extra-trusted-public-keys = caches.trustedPublicKeys;
  };
}
