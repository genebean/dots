# Bead Me Up, Scotty - a human-friendly web UI for the shared
# agents-beads-collaboration Beads coordination hub (genebean/agent-ideas#5
# Phase 2, explicitly gated on Phase 1's central Dolt server - that's now
# live and verified, see ../dolt-beads-server.nix and
# ../dolt-beads-runbook.md).
#
# Upstream: https://github.com/brendan-appstart/bead-me-up-scotty. No
# published container image exists anywhere (checked both the repo's own
# GHCR packages and the brendan-appstart user's GHCR packages - both
# empty), so this isn't the simple pull-a-tag case other containers/*.nix
# files are (e.g. audiobookshelf.nix's `image = "ghcr.io/advplyr/...:tag"`,
# already covered by the generic "OCI container images" Renovate rule).
# Packaging its Next.js build (standalone output, a prebuilt per-arch `bd`
# binary download, a separate Eleventy toolchain for an unrelated
# "showcase" feature) as a from-scratch Nix derivation isn't worth it next
# to an actively-maintained, already-correct Dockerfile - podman builds
# that Dockerfile directly from a pinned source checkout instead of Nix
# trying to reimplement it.
#
# Scotty shells out to `bd` itself (no HTTP API on the Beads side) against
# a mounted `.beads/` workspace - same server-mode metadata.json shape as
# every other client here. Server mode needs no embedded Dolt data at
# all, just the connection pointer, so there's nothing to migrate for this
# one. Authenticates as `gene` directly rather than a dedicated identity -
# considered a separate `scotty` SQL login (matching dots#825's "every
# agent/consumer gets its own identity" principle), but every identity
# already has GRANT ALL PRIVILEGES ON *.*, so there's no actual privilege
# isolation to gain; the only real tradeoff is credential-rotation
# independence, and for a single-user LAN-only deployment that wasn't
# worth a 9th secret. BEADS_ACTOR is `gene` either way - that part was
# never in question, it's what attributes UI writes to the human using
# it, a separate concern from which SQL login authenticates the
# connection. The image has no `git`, so `bd init`/Dolt-remote-sync don't
# work inside it (confirmed from upstream's own README) - the
# metadata.json below is written directly, never through a live `bd init`
# inside the container.
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  port = config.genebean.ports.scotty.port;
  # This container runs on podman's default bridge network (not
  # --network=host, unlike buzz.nix - that would collide with
  # psitransfer's existing use of port 3000), so it's in its own network
  # namespace: 127.0.0.1 inside the container is the container's own
  # loopback, not nixnuc's. The extraHosts entry added to nixnuc's own
  # /etc/hosts for same-host callers doesn't reach into here at all -
  # confirmed live (connection refused on 127.0.0.1:3307 from inside the
  # container). --add-host points this container specifically at
  # nixnuc's real LAN IP instead, which the dolt-beads server (bound to
  # 0.0.0.0) answers on correctly regardless of network namespace.
  nixnucLanIp = "192.168.20.190";

  # Same package every other client here is actually built against
  # (modules/shared/home/general/default.nix pulls the identical
  # attribute) - deriving from it instead of a literal string means a
  # nixpkgs-unstable bump that changes beads' version automatically
  # rebuilds this image with a matching bd, instead of silently drifting
  # back into the forward-schema-drift bug this session already hit once.
  unstablePkgs = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };

  container_name = "scotty";
  # `serviceName` is bare (correct for use as a `systemd.services` attrset
  # key) - sops-nix's `restartUnits` needs the full unit name, or it ends
  # up in the legacy activation-script restart path and gets handed to
  # switch-to-configuration-ng without a type suffix, which systemd's
  # D-Bus API rejects outright: "Unit name podman-X is not valid"
  # (dots#741) - same fix as buzz.nix.
  service_name = config.virtualisation.oci-containers.containers.${container_name}.serviceName;
  service_unit = "${service_name}.service";

  # renovate: tracks this repo's GitHub release tags (github-tags
  # datasource, customManagers entry in .github/renovate.json) - the
  # built-in nix manager only follows git refs/commits, not tags, same
  # situation as hermes-agent's flake-input pin. A Renovate-proposed rev
  # bump will NOT update the sha256 below automatically; fix the hash
  # (build will fail with the correct one in the error) before merging.
  scottyRev = "v0.3.2";
  scottySrc = pkgs.fetchFromGitHub {
    owner = "brendan-appstart";
    repo = "bead-me-up-scotty";
    rev = scottyRev;
    sha256 = "0nvx2j3hfhdcc6fn2wsapmppfbrypdjzb3hax0ixk1fhpr9ccz45";
  };
  # bd's own BD_VERSION default in the Dockerfile (1.1.0) predates the
  # schema migrations (up to v66) this server's beads_global already
  # needed - same version-skew bug this whole migration already hit once
  # with the Dolt server binary itself. Build with whatever bd version
  # every other client here actually uses, not a literal that can drift.
  bdVersionForImage = unstablePkgs.beads.version;
  # Bakes the bd version into the tag too, so a bd bump (bdVersionForImage
  # changes, scottyRev doesn't) still produces a new tag and actually
  # rebuilds - the "image exists" check below is a tag-keyed cache, not a
  # content hash.
  scottyImageTag = "scotty:${scottyRev}-bd${bdVersionForImage}";

  dataDir = "/var/lib/scotty";
  beadsRepoDir = "${dataDir}/beads-repo";
  configDir = "${dataDir}/config";

  # Server-mode-only metadata.json (no embedded Dolt data needed) - same
  # shape as every other client's .beads/metadata.json, just this
  # identity's own username. Seeded once, not clobbered on every
  # activation, in case bd ever needs to add its own fields at runtime.
  scottyMetadataFile = pkgs.writeText "scotty-metadata.json" (
    builtins.toJSON {
      database = "dolt";
      backend = "dolt";
      dolt_mode = "server";
      dolt_server_host = "dolt-beads.home.technicalissues.us";
      dolt_server_port = 3307;
      dolt_server_user = "gene";
      dolt_database = "beads_global";
    }
  );
in
{
  sops = {
    # gene's existing secret, already in use elsewhere (e.g. rainbow-planet's
    # own `gene` identity) - sops-nix allows the same secret declared in
    # multiple places as long as each host can already decrypt the file,
    # which nixnuc already can (other secrets here already come from the
    # same shared/secrets.yaml).
    secrets.dolt_beads_gene_password = {
      sopsFile = ../../../../shared/secrets.yaml;
      restartUnits = [ service_unit ];
    };
    templates."scotty-dolt-password-env" = {
      content = ''
        BEADS_DOLT_PASSWORD=${config.sops.placeholder.dolt_beads_gene_password}
      '';
      restartUnits = [ service_unit ];
    };
  };

  systemd = {
    tmpfiles.rules = [
      # World-writable (0777), matching the upstream image's own stated
      # fix for exactly this cross-UID bind-mount scenario (container
      # runs as uid 1001 "nextjs", not whatever uid owns the host path).
      "d ${dataDir} 0750 root root -"
      # Both the repo root and .beads itself need to be writable: bd
      # creates a workspace gate lock file (.beads.gate.lock) directly in
      # the repo root, not just inside .beads/ - confirmed live (soft
      # "continuing ungated" warning without this).
      "d ${beadsRepoDir} 0777 root root -"
      "d ${beadsRepoDir}/.beads 0777 root root -"
      "d ${configDir} 0777 root root -"
    ];

    services = {
      scotty-build-image = {
        description = "Build the Bead Me Up, Scotty container image (${scottyRev}) from its Dockerfile";
        wantedBy = [ "multi-user.target" ];
        before = [ service_unit ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          if ! ${pkgs.podman}/bin/podman image exists ${scottyImageTag}; then
            ${pkgs.podman}/bin/podman build \
              --build-arg BD_VERSION=${bdVersionForImage} \
              -t ${scottyImageTag} \
              ${scottySrc}
          fi
          if [ ! -s ${beadsRepoDir}/.beads/metadata.json ]; then
            install -m 0644 ${scottyMetadataFile} ${beadsRepoDir}/.beads/metadata.json
          fi
        '';
      };

      ${service_name} = {
        after = [ "scotty-build-image.service" ];
        requires = [ "scotty-build-image.service" ];
      };
    };
  };

  virtualisation.oci-containers.containers.${container_name} = {
    image = scottyImageTag;
    autoStart = true;
    environment = {
      BEADS_REPO = "/data";
      BEADS_DOLT_SERVER_TLS = "1";
      BEADS_DOLT_SERVER_USER = "gene";
      BEADS_ACTOR = "gene";
      # No SCOTTY_ALLOWED_HOSTS needed: per upstream's own docs, IP-address
      # access (which is how this is reached for now - no nginx vhost, no
      # hostname) is allowed by default. Only a hostname needs explicit
      # allowlisting.
      # Upstream ships a public, ingestion-only PostHog token with
      # telemetry enabled by default. agent-ideas#5 explicitly requires
      # "optional usage telemetry disabled" - an empty value disables it
      # regardless of the in-app preference toggle.
      POSTHOG_KEY = "";
    };
    environmentFiles = [
      config.sops.templates."scotty-dolt-password-env".path
    ];
    volumes = [
      "${beadsRepoDir}:/data:rw"
      "${configDir}:/home/nextjs/.config/bead-me-up-scotty:rw"
      # The final runner stage (node:slim) ships no CA bundle at all -
      # confirmed live: bd's own TLS handshake against dolt-beads failed
      # with "certificate signed by unknown authority" even though the
      # exact same chain verifies fine (openssl s_client, verify return
      # code 0) from a host with a normal trust store. Bind-mount
      # nixnuc's own bundle in at the path Go's x509 verifier expects.
      "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
    ];
    # Reachable via nixnuc's LAN IP directly for now - no nginx vhost, no
    # TLS, no auth. Deliberately scoped this way (not internet-facing:
    # nixnuc's physical firewall only forwards 80/443, and openFirewall
    # below only opens this host's own software firewall to the LAN this
    # port's traffic actually reaches). Revisit before any wider exposure
    # - see the auth discussion in agents-beads-collaboration-3kt.
    ports = [ "${toString port}:3000" ];
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
      "--add-host=dolt-beads.home.technicalissues.us:${nixnucLanIp}"
    ];
  };
}
