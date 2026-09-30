# Buzz relay: the coordinator's control surface (hermes-agent-fleet-plan
# issue #23, ADR 0006), replacing Matrix. Prebuilt container image
# (ghcr.io/block/buzz), not the fosskar/buzz-flake NixOS module — same
# reasoning as rustfs.nix: the image lets us skip an expensive from-source
# Rust+Node build for an upstream-only-published service. The hardening
# posture below (--cap-drop=ALL, no-new-privileges) is cribbed from that
# project's own module rather than reinvented from scratch.
#
# --network=host: lets the relay reach nixnuc's existing Postgres cluster
# and RustFS over plain loopback TCP exactly like a native process would —
# no podman-bridge-to-host complexity. Every port the relay's own env vars
# bind to is explicitly loopback-only (127.0.0.1); the public endpoint is
# nginx reverse-proxying in front (see default.nix's virtualHosts) — nothing
# is forwarded to the internet on nixnuc except 80/443 regardless.
#
# No separate member-reconciliation service: per upstream's own NOSTR.md, the
# relay bootstraps RELAY_OWNER_PUBKEY as the owner automatically on startup —
# a `buzz-admin add-member` oneshot would just duplicate that.
#
# Not adopting Buzz's NIP-34 git hosting (ADR 0006) — BUZZ_GIT_REPO_PATH
# still needs to point somewhere (the relay's own git-hydrate/pack cache for
# a feature this plan never uses), so it stays on root, not /orico.
{
  config,
  pkgs,
  ...
}:
let
  home_domain = "home.technicalissues.us";
  relay_url = "wss://buzz.${home_domain}";

  container_name = "buzz";
  service_name = config.virtualisation.oci-containers.containers.${container_name}.serviceName;
in
{
  virtualisation.oci-containers.containers.${container_name} = {
    autoStart = true;
    environment = {
      BUZZ_ALLOW_NIP_OA_AUTH = "true";
      BUZZ_AUTO_MIGRATE = "true";
      BUZZ_BIND_ADDR = "127.0.0.1:${toString config.genebean.ports.buzz-relay.port}";
      BUZZ_GIT_CONFORMANCE_PROBE = "true";
      BUZZ_GIT_REPO_PATH = "/data/git";
      BUZZ_HEALTH_PORT = toString config.genebean.ports.buzz-health.port;
      BUZZ_METRICS_PORT = toString config.genebean.ports.buzz-metrics.port;
      BUZZ_REQUIRE_AUTH_TOKEN = "true";
      BUZZ_REQUIRE_RELAY_MEMBERSHIP = "true";
      BUZZ_S3_ADDRESSING_STYLE = "path";
      BUZZ_S3_BUCKET = "buzz-media";
      BUZZ_S3_ENDPOINT = "http://127.0.0.1:${toString config.genebean.ports.rustfs-api.port}";
      RELAY_URL = relay_url;
      RUST_LOG = "buzz_relay=info,buzz_db=info,buzz_auth=info,buzz_pubsub=info,tower_http=info";
    };
    environmentFiles = [
      config.sops.secrets.buzz_env.path
      config.sops.secrets.fleet_owner_pubkey.path
    ];
    extraOptions = [
      "--network=host"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
    image = "ghcr.io/block/buzz:sha-fccc07e";
    volumes = [
      "/var/lib/buzz-relay:/data/git"
    ];
  };

  # Device pairing (NIP-AB — desktop/mobile key transfer) is a separate
  # binary from buzz-relay, bundled in the same image but not started by its
  # default entrypoint. Fully stateless/in-memory (confirmed against
  # buzz-pair-relay's own source — no DB, no Redis, one env var), so nothing
  # here beyond the bind address. Desktop/mobile clients derive
  # wss://buzz.${home_domain}/pair from the main relay's NIP-11
  # supported_nips list advertising 43; nginx routes that path here
  # (default.nix's virtualHosts) instead of to buzz-relay's own port.
  virtualisation.oci-containers.containers.buzz-pair-relay = {
    autoStart = true;
    entrypoint = "/usr/local/bin/buzz-pair-relay";
    environment = {
      BUZZ_PAIR_RELAY_BIND_ADDR = "127.0.0.1:${toString config.genebean.ports.buzz-pair-relay.port}";
    };
    extraOptions = [
      "--network=host"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
    image = "ghcr.io/block/buzz:sha-fccc07e";
  };

  # Podman doesn't auto-create bind-mount host directories (unlike Docker);
  # the image's own useradd (uid/gid 1000, see its Dockerfile) needs this
  # pre-created and owned to match, since a bind mount overrides whatever
  # ownership the image set up internally at build time.
  systemd.tmpfiles.rules = [
    "d /var/lib/buzz-relay 0750 1000 1000 -"
  ];

  services.postgresql = {
    ensureDatabases = [ "buzz" ];
    ensureUsers = [
      {
        name = "buzz";
        ensureDBOwnership = true;
      }
    ];
  };

  # New named instance on the existing Redis server, per the pattern already
  # used for redis-nextcloud — not a separate Redis service.
  services.redis.servers.buzz = {
    bind = "127.0.0.1";
    enable = true;
    port = 6380;
    requirePassFile = config.sops.secrets.buzz_redis_password.path;
  };

  sops.secrets = {
    # BUZZ_RELAY_PRIVATE_KEY=<64 hex chars, from `podman run --rm
    #   ghcr.io/block/buzz:sha-fccc07e buzz-admin generate-key` — a stateless
    #   keypair generator, no running relay needed. Preserve this value across
    #   restarts and backups; it's the relay's own stable Nostr identity>
    # BUZZ_GIT_HOOK_HMAC_SECRET=<32+ random chars, e.g. `openssl rand -hex 32`>
    # DATABASE_URL=postgres://buzz:<same password as buzz_postgres_password
    #   below>@127.0.0.1:5432/buzz
    # REDIS_URL=redis://:<same password as buzz_redis_password
    #   below>@127.0.0.1:6380
    # BUZZ_S3_ACCESS_KEY=<same value as rustfs_env's RUSTFS_ACCESS_KEY>
    # BUZZ_S3_SECRET_KEY=<same value as rustfs_env's RUSTFS_SECRET_KEY>
    buzz_env = {
      restartUnits = [ service_name ];
    };

    # RELAY_OWNER_PUBKEY=<hex pubkey> — Jed's dedicated Nostr identity
    #   (hermes-agent-fleet-plan issue #24). Lives in the shared secrets file,
    #   not buzz_env, because it's a fleet-wide value other Bots will also
    #   need, not something specific to this one relay. The relay bootstraps
    #   this pubkey as the owner automatically on startup — no separate
    #   membership step needed.
    fleet_owner_pubkey = {
      restartUnits = [ service_name ];
      sopsFile = ../../../../shared/secrets.yaml;
    };

    # Raw password only — consumed by the ALTER ROLE oneshot below and by
    # DATABASE_URL above, which must match. Deliberately not the same secret
    # as buzz_env, so that file only carries what the container needs.
    buzz_postgres_password = {
      restartUnits = [ "buzz-postgres-password.service" ];
    };

    # Raw password only, matching REDIS_URL above.
    buzz_redis_password = {
      restartUnits = [ "redis-buzz.service" ];
    };
  };

  systemd.services = {
    # ensureUsers only ever gives peer auth (Unix socket, no password); the
    # relay connects over loopback TCP (--network=host), which needs a real
    # password — NixOS's default pg_hba already allows md5 auth on TCP, no
    # config changes needed there, just an actual password to set. Piped via
    # heredoc/stdin rather than psql -c, so the value never appears in this
    # process's own argv (visible to any other user via /proc/<pid>/cmdline).
    buzz-postgres-password = {
      after = [ "postgresql.service" ];
      description = "Set the buzz Postgres role's password";
      requires = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = pkgs.writeShellScript "buzz-postgres-password" ''
          set -euo pipefail
          ${config.services.postgresql.package}/bin/psql -tA <<SQL
          ALTER ROLE buzz WITH PASSWORD '$(cat "$CREDENTIALS_DIRECTORY/password")';
          SQL
        '';
        LoadCredential = [ "password:${config.sops.secrets.buzz_postgres_password.path}" ];
        RemainAfterExit = true;
        Type = "oneshot";
        User = "postgres";
      };
    };

    # RustFS starts with no buckets; Buzz's own startup conformance probe
    # (BUZZ_GIT_CONFORMANCE_PROBE) fails hard against a bucket that doesn't
    # exist yet.
    buzz-media-bucket = {
      after = [ "podman-rustfs.service" ];
      description = "Ensure the buzz-media bucket exists in RustFS";
      requires = [ "podman-rustfs.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = config.sops.secrets.rustfs_env.path;
        ExecStart = pkgs.writeShellScript "buzz-media-bucket" ''
          set -euo pipefail
          export AWS_ACCESS_KEY_ID="$RUSTFS_ACCESS_KEY"
          export AWS_SECRET_ACCESS_KEY="$RUSTFS_SECRET_KEY"
          export AWS_DEFAULT_REGION="us-east-1"
          endpoint="http://127.0.0.1:${toString config.genebean.ports.rustfs-api.port}"
          ${pkgs.awscli2}/bin/aws --endpoint-url "$endpoint" s3api head-bucket --bucket buzz-media 2>/dev/null \
            || ${pkgs.awscli2}/bin/aws --endpoint-url "$endpoint" s3api create-bucket --bucket buzz-media
        '';
        RemainAfterExit = true;
        Type = "oneshot";
      };
    };

    ${service_name} = {
      after = [
        "buzz-media-bucket.service"
        "buzz-postgres-password.service"
        "podman-rustfs.service"
      ];
      requires = [
        "buzz-media-bucket.service"
        "buzz-postgres-password.service"
        "podman-rustfs.service"
      ];
    };
  };
}
