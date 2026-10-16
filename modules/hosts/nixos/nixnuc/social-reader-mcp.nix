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

      bindAddress = "127.0.0.1";
      environmentFile = config.sops.templates.social_reader_mcp_env.path;
      # Loopback-only - hermes-agent-fleet-plan issue 37 puts nginx in front
      # (TLS termination + source-IP restriction to tcan-left only) rather
      # than exposing this directly. The bearer token
      # (SOCIAL_READER_MCP_HTTP_TOKEN in environmentFile) remains the
      # actual auth mechanism; nginx only handles transport and reachability.
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
  sops = {
    secrets = {
      # Same sops secret Danny's own hermes_danny_mcp_token.envFileAs
      # reshaping reads (modules/hosts/nixos/tcan-left/hermes/danny/
      # home.nix) - one value, one place it's authored
      # (modules/shared/secrets.yaml), read by both ends instead of two
      # independently-maintained copies that can (and did - confirmed
      # live, 2026-10-16) silently drift apart. nixnuc is already a
      # recipient for modules/shared/secrets.yaml (.sops.yaml), so this
      # needs no new key grants.
      hermes_danny_mcp_token = {
        sopsFile = ../../../shared/secrets.yaml;
        restartUnits = [ "social-reader-mcp-http.service" ];
      };

      social_reader_mcp_env = {
        owner = "social-reader-mcp";
        restartUnits = [ "social-reader-mcp-http.service" ];
      };
    };

    # Reassembles social_reader_mcp_env's own two lines (MASTODON_MAIN_TOKEN,
    # BSKY_PERSONAL_APP_PW - unchanged) plus a SOCIAL_READER_MCP_HTTP_TOKEN
    # line sourced from the shared secret above, instead of social_reader_mcp_env
    # carrying its own independent copy of that token.
    templates.social_reader_mcp_env = {
      content = ''
        ${config.sops.placeholder.social_reader_mcp_env}
        SOCIAL_READER_MCP_HTTP_TOKEN=${config.sops.placeholder.hermes_danny_mcp_token}
      '';
      owner = "social-reader-mcp";
      restartUnits = [ "social-reader-mcp-http.service" ];
    };
  };

  users = {
    groups.social-reader-mcp = { };
    users.social-reader-mcp = {
      group = "social-reader-mcp";
      isSystemUser = true;
    };
  };
}
