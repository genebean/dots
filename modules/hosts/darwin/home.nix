{
  config,
  username,
  ...
}:
{
  sops.age.keyFile = "/Users/${username}/Library/Application Support/sops/age/keys.txt";

  # Auth for the self-hosted Attic cache (genebean/dots#677) - the
  # substituter URL/key live in modules/genebean/data/nix-caches.nix like
  # every other cache. Home-manager's own nix.settings here, not a
  # system-level nix-darwin one: this host's system-level sops module
  # isn't imported (only the home-manager one is), and this user is
  # already trusted, so this client-side setting is honored either way.
  sops.secrets."attic-netrc".sopsFile = ../../shared/secrets.yaml;
  nix.settings.netrc-file = config.sops.secrets."attic-netrc".path;
}
