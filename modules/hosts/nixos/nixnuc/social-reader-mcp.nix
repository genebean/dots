{
  config,
  ...
}:
{
  services.social-reader-mcp = {
    enable = true;

    bluesky = [
      {
        appPasswordEnv = "BSKY_PERSONAL_APP_PW";
        handle = "genebean.bsky.social";
        id = "personal";
      }
    ];

    http = {
      enable = true;

      bindAddress = "0.0.0.0";
      environmentFile = config.sops.secrets.social_reader_mcp_env.path;
      # Bind on all interfaces — LAN-only access, no nginx proxy in front.
      # The bearer token (SOCIAL_READER_MCP_HTTP_TOKEN in environmentFile)
      # is the sole auth mechanism.
      port = config.genebean.ports.social-reader-mcp.port;
    };

    mastodon = [
      {
        accessTokenEnv = "MASTODON_MAIN_TOKEN";
        id = "main";
        instanceUrl = "https://fosstodon.org";
      }
    ];

    nostr = [
      {
        id = "main";
        npub = "npub1mwsk3ly4lk7efdqqjm62dkc699kqapwyyvdley3xljjm0lxruh9qzvu46p";
        relays = [
          "wss://nostr.data.haus"
          "wss://relay.primal.net"
          "wss://relay.damus.io"
        ];
      }
    ];

    user = "social-reader-mcp";
  };

  # Dedicated system user — required so sops can assign ownership of the
  # EnvironmentFile and tmpfiles can create the cursor-state directory with
  # a known, persistent owner (DynamicUser doesn't work here for that reason).
  sops.secrets.social_reader_mcp_env = {
    owner = "social-reader-mcp";
    restartUnits = [ "social-reader-mcp-http.service" ];
  };

  users = {
    groups.social-reader-mcp = { };
    users.social-reader-mcp = {
      group = "social-reader-mcp";
      isSystemUser = true;
    };
  };
}
