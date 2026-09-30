# Hindsight's "gene-personal" memory bank — see ADR 0007 and
# docs/hindsight-memory-evaluation.md in hermes-agent-fleet-plan. Durable
# cross-tool, cross-session facts/preferences for the owner, read by
# interactive Claude Code/Codex sessions via MCP.
#
# Two containers (app + its own dedicated Postgres/pgvector), matching
# Hindsight's own reference docker-compose rather than the host's existing
# Postgres 16 cluster: reaching host Postgres from inside a podman container
# would require widening listen_addresses and trusting the podman bridge
# subnet in the host firewall, real surface for very little benefit. A
# private podman network between just these two containers needs none of
# that.
#
# Tailscale-only for now — this bank holds personal preference data behind a
# single hsk_ bearer key, so it doesn't get the public/LAN exposure a shared
# service might. `allowed_interfaces` is a list specifically so adding the
# LAN (nixnuc's `vlan23`) later is a one-line change, not a redesign.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  volume_base = "/var/lib/hindsight-gene-personal";
  network_name = "hindsight-gene-personal-net";
  db_container_name = "hindsight-gene-personal-db";

  # Not "hindsight-gene-personal" (no suffix) — kept distinct from
  # db_container_name for clarity. (A "Unit name ... is not valid" message
  # was seen from switch-to-configuration during early real deploys; traced
  # to the app container crash-looping on missing Codex auth at the time,
  # not to unit naming — a later clean deploy did this exact same
  # old-name-stops/new-name-starts transition with no such message.)
  app_container_name = "hindsight-gene-personal-app";

  # Bare names for use as systemd.services attribute keys (NixOS appends
  # ".service" itself); the "_unit" variants carry the suffix back on for
  # after/requires, which validate strictly against the full unit name.
  network_service_name = "podman-network-${network_name}";
  db_service_name = config.virtualisation.oci-containers.containers.${db_container_name}.serviceName;
  app_service_name =
    config.virtualisation.oci-containers.containers.${app_container_name}.serviceName;
  network_service_unit = "${network_service_name}.service";
  db_service_unit = "${db_service_name}.service";
  app_service_unit = "${app_service_name}.service";

  allowed_interfaces = [
    "tailscale0"
    # "vlan23"  # nixnuc's LAN interface — uncomment to also allow home-LAN access
  ];
in
{
  virtualisation.oci-containers.containers = {
    ${db_container_name} = {
      autoStart = true;
      environment = {
        POSTGRES_DB = "hindsight";
        POSTGRES_USER = "hindsight";
      };
      environmentFiles = [ config.sops.secrets.hindsight_gene_personal_db_env.path ];
      extraOptions = [ "--network=${network_name}" ];
      image = "pgvector/pgvector:0.8.6-pg18";
      volumes = [
        "${volume_base}/pg-data:/var/lib/postgresql/18/docker"
      ];
    };

    ${app_container_name} = {
      autoStart = true;
      dependsOn = [ db_container_name ];
      environment = {
        # Local Ollama backend (ollama.nix) instead of the owner's
        # ChatGPT/Codex subscription — this task (fact extraction/mental-
        # model refresh) is structured, not deep reasoning, and a small
        # local model is genuinely sufficient. Avoids depending on that
        # subscription's quota for a background task; also keeps Claude
        # Code/Codex CLI usage free for the owner's own interactive work.
        # host.containers.internal: podman's own DNS name for reaching a
        # host-native service from inside a container on a custom bridge
        # network (hindsight-gene-personal-net) — no host IP to hardcode.
        HINDSIGHT_API_LLM_PROVIDER = "ollama";
        HINDSIGHT_API_LLM_BASE_URL = "http://host.containers.internal:${toString config.genebean.ports.ollama.port}/v1";
        HINDSIGHT_API_LLM_MODEL = "qwen2.5:7b-instruct";
        HINDSIGHT_API_WORKER_ID = app_container_name;
      };
      environmentFiles = [ config.sops.secrets.hindsight_gene_personal_app_env.path ];
      extraOptions = [
        "--network=${network_name}"
        "--shm-size=1g" # needed for local embedding/reranking model operations
      ];
      image = "ghcr.io/vectorize-io/hindsight:0.10.1";
      ports = [
        "${toString config.genebean.ports.hindsight-gene-personal-api.port}:8888"
        "${toString config.genebean.ports.hindsight-gene-personal-ui.port}:9999"
      ];
      volumes = [
        # Whole container home dir: covers the embedded-model cache, the
        # codex subscription login state, and any other config Hindsight
        # keeps under $HOME — none of these subpaths are documented
        # precisely enough to mount narrower.
        "${volume_base}/app-data:/home/hindsight"
      ];
    };
  };

  networking.firewall.interfaces = lib.genAttrs allowed_interfaces (_: {
    allowedTCPPorts = [
      config.genebean.ports.hindsight-gene-personal-api.port
      config.genebean.ports.hindsight-gene-personal-ui.port
    ];
  });

  # Only the app container's home dir (config, cache, subscription login
  # state) goes through restic directly — pg-data does not, matching how the
  # host's own Postgres is backed up: via logical pg_dump output below, into
  # the same /var/backup/postgresql restic already covers, not the raw data
  # directory.
  services.restic.backups.daily.paths = [ "${volume_base}/app-data" ];

  sops.secrets = {
    # HINDSIGHT_API_DATABASE_URL=postgresql://hindsight:<same password as
    # hindsight_gene_personal_db_env>@hindsight-gene-personal-db:5432/hindsight
    hindsight_gene_personal_app_env = {
      restartUnits = [ app_service_name ];
    };

    # POSTGRES_PASSWORD=<password> — consumed by both the db container
    # (sets the role's password) and the backup service below
    # (authenticates pg_dump). Deliberately not shared with the app
    # container's secret above even though the value matches, so each
    # container's environmentFile only carries what that container needs.
    hindsight_gene_personal_db_env = {
      restartUnits = [
        db_service_name
        "hindsight-gene-personal-db-backup.service"
      ];
    };
  };

  systemd = {
    services = {
      # virtualisation.oci-containers has no first-class multi-container
      # network option, so the shared network the app and db containers use
      # to reach each other by name is created out-of-band via a oneshot
      # unit both depend on.
      ${network_service_name} = {
        after = [ "network-online.target" ];
        description = "Create the podman network for the gene-personal Hindsight bank";
        serviceConfig = {
          ExecStart = "${pkgs.podman}/bin/podman network create --ignore ${network_name}";
          ExecStop = "${pkgs.podman}/bin/podman network rm -f ${network_name}";
          RemainAfterExit = true;
          Type = "oneshot";
        };
        wants = [ "network-online.target" ];
      };

      ${app_service_name} = {
        # Soft ordering only (after, not requires) — the API/UI and most
        # read/write operations don't need the LLM backend, only the
        # background retain/reflect workers do. Starting anyway if the model
        # pull is slow/fails means those calls just fail individually and
        # retry, rather than blocking this whole container.
        after = [
          network_service_unit
          "ollama-model-loader.service"
        ];
        requires = [ network_service_unit ];
      };

      ${db_service_name} = {
        after = [ network_service_unit ];
        requires = [ network_service_unit ];
        # Create-once, not tmpfiles: postgres's own entrypoint chowns
        # pg-data's *contents* to its internal non-root uid on init, but
        # never the top-level directory itself. A tmpfiles `d` rule
        # re-enforces root:root on that top-level dir on every single
        # deploy regardless, silently blocking that uid's traversal the
        # next time something opens a file it hadn't touched before (hit
        # this for real: a fresh app-container connection failed with
        # "could not open file... Permission denied" after an otherwise
        # successful deploy). `mkdir -p` only acts the first time the path
        # is missing and never touches an already-existing directory.
        serviceConfig.ExecStartPre = "+${pkgs.coreutils}/bin/mkdir -p -m 0751 ${volume_base}/pg-data";
      };

      # Logical backup of the containerized Postgres, run the same way
      # services.postgresqlBackup does for the host's own cluster: pg_dump
      # to /var/backup/postgresql, picked up by the existing restic daily
      # backup — no new restic path needed, it's already in
      # nixnuc/default.nix's list.
      hindsight-gene-personal-db-backup = {
        after = [ db_service_unit ];
        description = "Dump the gene-personal Hindsight Postgres database";
        requires = [ db_service_unit ];
        serviceConfig = {
          EnvironmentFile = config.sops.secrets.hindsight_gene_personal_db_env.path;
          ExecStart = pkgs.writeShellScript "hindsight-gene-personal-db-backup" ''
            set -euo pipefail
            install -d -m 0700 /var/backup/postgresql
            dest=/var/backup/postgresql/hindsight-gene-personal.sql.gz

            # This timer has Persistent=true, so the very first time it's
            # ever activated (every deploy that introduces it fresh) it
            # immediately fires a catch-up run rather than waiting for
            # 23:00 — normal systemd timer behavior, not something to
            # fight. On a brand-new deploy that races against the db
            # container's own Postgres still initializing. Rather than
            # block on it (which risks exceeding deploy-rs's own
            # confirmation timeout and rolling back an otherwise-successful
            # deploy), give it a short grace window and skip cleanly if
            # Postgres isn't up yet — the scheduled 23:00 run is the real
            # backup mechanism; this opportunistic one is a bonus, not
            # something that should ever block a deploy.
            ready=0
            for _ in $(seq 1 10); do
              if ${pkgs.podman}/bin/podman exec ${db_container_name} pg_isready -U hindsight -d hindsight \
                >/dev/null 2>&1; then
                ready=1
                break
              fi
              sleep 1
            done
            if [ "$ready" -eq 0 ]; then
              echo "Postgres not ready yet, skipping this run — the 23:00 timer will retry"
              exit 0
            fi

            ${pkgs.podman}/bin/podman exec -e PGPASSWORD="$POSTGRES_PASSWORD" ${db_container_name} \
              pg_dump -h 127.0.0.1 -U hindsight -d hindsight \
              | ${pkgs.gzip}/bin/gzip -c > "$dest.tmp"
            mv "$dest.tmp" "$dest"
          '';
          Type = "oneshot";
        };
      };
    };

    timers.hindsight-gene-personal-db-backup = {
      description = "Daily dump of the gene-personal Hindsight Postgres database";
      timerConfig = {
        OnCalendar = "*-*-* 23:00:00"; # same schedule as services.postgresqlBackup for the host cluster
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };

    # Podman, unlike Docker, does not auto-create a missing bind-mount
    # source directory — it fails the whole container start with
    # `statfs: no such file or directory` instead. Hit this on a real
    # deploy before adding these rules.
    tmpfiles.rules = [
      # 0751, not 0750: the owner still needs `--x` on this parent to reach
      # app-data by name for one-off host-side operations (e.g. running the
      # codex CLI directly to do the one-time OAuth login) without granting
      # read/list access to its other contents. (pg-data's own directory is
      # created separately below, via ExecStartPre, not a tmpfiles rule.)
      "d ${volume_base} 0751 root root -"
      # 1000:1000 — the hindsight image sets a fixed non-root USER directly
      # (uid=1000(hindsight) gid=1000(hindsight), confirmed by `podman run
      # --entrypoint id`), unlike the postgres image below, which starts as
      # root and drops privileges itself via its own entrypoint script. So
      # this one specifically needs host-side ownership to match, or the
      # containerized process can't even stat a nonexistent file under its
      # own $HOME (surfaced as a confusing PermissionError, not ENOENT).
      "d ${volume_base}/app-data 0750 1000 1000 -"
      # Pre-created (not left to the codex CLI or the app itself) so the
      # one-time host-side `codex auth login` step has somewhere to write
      # auth.json with the right ownership from the start.
      "d ${volume_base}/app-data/.codex 0750 1000 1000 -"
    ];
  };
}
