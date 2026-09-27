{ config, ... }:
{
  services.hermes-social-digest-collect = {
    enable = true;

    # Loopback call to services.social-reader-mcp's HTTP listener on this
    # same host — no LAN/Tailscale hop for this consumer.
    environmentFile = config.sops.secrets.hermes_social_digest_mcp_token.path;
  };

  # Narrowly scoped to just the bearer token this collector needs to
  # authenticate to social-reader-mcp. Deliberately NOT the same secret file
  # social-reader-mcp itself uses (social_reader_mcp_env), which also carries
  # Mastodon/Bluesky/Nostr credentials this collector has no reason to read.
  sops.secrets.hermes_social_digest_mcp_token = {
    owner = "hermes-social-digest";
    restartUnits = [
      "hermes-social-digest-catchup.service"
      "hermes-social-digest-collect.service"
    ];
  };
}
