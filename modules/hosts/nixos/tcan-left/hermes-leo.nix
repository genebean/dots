# Hermes agent fleet, Phase 2 (hermes-agent-fleet-plan issue 22): the
# coordinator (hermes-leo, Chief of Staff per docs/agent-roster.md) as a real
# Hermes Bot profile. Host decided in ADR 0008 (supersedes ADR 0005's
# nixnuc choice) - structural reason, not performance: this host carries none
# of nixnuc's Forgejo/Pocket-ID co-location exposure.
#
# This one services.hermes-agent instance is shared by TWO same-trust-tier
# profiles, per hermes-agent-fleet-plan's authority-boundaries.md "Open
# authority questions" question 7: Hermes's own multiplexed gateway
# (gateway.multiplex_profiles, default-on) serves many profiles from one
# instance/Unix user; per-profile credentials are never shared regardless.
# That's why this keeps the module's own plain default user/group
# ("hermes"), not "hermes-leo" - hermes-leo is one of the profiles riding on
# this shared instance, not the Unix-level identity itself. A future
# profile that actually needs genuine OS-level separation (untrusted
# content, a different trust tier) gets its own dedicated user and its own
# nspawn/VM instance instead of multiplexing here - this host's "hermes" is
# never ambiguous as long as it stays the only non-containerized instance
# on it.
#
#   - hermes-leo (coordinator): the DEFAULT profile, configured directly via
#     this module's own options below. Holds only its Buzz identity
#     (dedicated Nostr keypair) - no Forgejo credential. Model/Codex auth is
#     a one-time interactive login, not declared here - see below.
#   - hermes-charlie (Charlie, Forgejo-scoped planning worker): a SECOND,
#     NAMED profile. Hermes's own per-profile credential model is imperative
#     (`hermes profile create`), not expressible through this module's flat
#     options - see the activation note below for the one-time setup this
#     still needs on the host itself.
#
# hermes-leo dispatches to hermes-charlie via message_agent for anything
# Forgejo-related, rather than holding that credential itself - this is
# what makes "coordinator cannot mutate protected hosts" true by
# construction (per authority-boundaries.md's pre-Phase-2 checklist), not
# just by policy.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.hermes-agent = {
    enable = true;

    # Exports the `hermes` CLI + HERMES_HOME to interactive shells (not just
    # the gateway systemd unit's own PATH) - needed for the one-time
    # `hermes model`/`hermes profile create` setup steps below.
    addToSystemPackages = true;

    # buzz-cli (pkgs/buzz-cli): outbound Buzz messages shell out to this
    # binary ("JSON in, JSON out") - not packaged anywhere upstream, built
    # from source. See that package's own comments for why.
    extraPackages = [ pkgs.buzz-cli ];

    # SOUL.md = who Leo is (persona, voice, delegation philosophy) - per
    # Hermes's own docs (website/docs/guides/use-soul-with-hermes.md), this
    # is identity/style only, never workflow or authority rules. Only
    # reaches the DEFAULT profile (hermes-leo) - hermesHomeFiles installs
    # into the ambient HERMES_HOME, which named profiles (hermes-charlie)
    # don't share. See the one-time setup note below for Charlie's own copy.
    hermesHomeFiles."SOUL.md" = ./soul-leo.md;

    # AGENTS.md = Leo's hard authority boundary (authority-boundaries.md),
    # kept deliberately separate from SOUL.md per the same docs. `documents`
    # needs an explicit workingDirectory or the module refuses to build -
    # this is the NixOS module's own unchanged default, just spelled out.
    workingDirectory = "${config.services.hermes-agent.stateDir}/workspace";
    documents."AGENTS.md" = ./agents-leo.md;

    # hermes-leo's own (default profile) settings.
    settings = {
      # Reuses gene-personal's existing Codex/ChatGPT subscription, but NOT
      # via sops/authFile - Hermes's own auth.json has a different internal
      # schema than ~/.codex/auth.json (the Codex CLI's own file), and the
      # conversion between them only runs inside an interactive
      # `hermes model` login prompt, not automatically at gateway startup.
      # Hermes's own code explicitly recommends a fresh login over
      # importing anyway ("a separate login is recommended... to avoid
      # conflicts with Codex CLI / VS Code"). So: auth.json for this host
      # gets populated by running `hermes model` interactively, once, as
      # the hermes user - not declared here at all. No implicit default
      # model on the Codex route either - pick the exact string deliberately.
      model = {
        default = "gpt-5.6-sol"; # matches gene-personal's existing choice, and Codex's own default variant
        provider = "codex";
      };

      # Buzz is the coordinator's interactive surface, not Hermes's own
      # dashboard/TUI.
      backend.mode = "none";

      # Buzz platform plugin. Confirmed from upstream docs
      # (website/docs/user-guide/messaging/buzz.md): can be configured via
      # config.yaml ("gateway.platforms.buzz", set here) or purely via env
      # vars (used below for the actual values) - enabled here explicitly
      # rather than relying on env vars alone to flip it on.
      gateway.platforms.buzz.enabled = true;
    };

    # Buzz relay URL and allowed-users list aren't secret (public relay
    # address, public npubs) - only BUZZ_PRIVATE_KEY is. BUZZ_ALLOWED_USERS
    # is a placeholder: fill in the owner's actual Jed/fleet-owner npub
    # (issue 24), not the agent's own - restricting the coordinator to
    # respond only to its owner until the fleet actually needs wider access.
    environment = {
      BUZZ_RELAY_URL = "https://buzz.home.technicalissues.us";
      BUZZ_ALLOWED_USERS = "npub1t8raljleztelnpe6e6ajppg8lw5xpxjssvtm7pex9mc6rrkdvneqds7u90"; # Jed, the owner's fleet-owner identity (issue 24)
    };

    # Buzz identity: a dedicated Nostr keypair (BUZZ_PRIVATE_KEY), never the
    # owner's own npub.
    environmentFiles = [
      config.sops.secrets.hermes_leo_buzz_identity.path
    ];
  };

  # Hardening gap: the upstream module's own commonServiceConfig
  # (NoNewPrivileges, ProtectSystem=strict, ProtectHome=false, PrivateTmp)
  # is lighter than ADR 0005/0008 require. Layered on top via the
  # HermesSocialDigestPipeline hardening template (nix/module.nix) - NixOS
  # merges serviceConfig attrsets across module files, no upstream patch
  # needed. ProtectHome needs mkForce: the upstream module sets it to
  # `false` at normal priority, so a same-priority `true` would conflict.
  #
  # Deliberately NOT included from that template: StateDirectoryMode.
  # It only has any effect paired with systemd's own `StateDirectory=`
  # option, which this module doesn't use - it manages cfg.stateDir itself
  # via systemd.tmpfiles.rules with deliberately group-writable (2770)
  # permissions, for its own multi-profile/shared-group design. Setting
  # StateDirectoryMode alone here would be a silent no-op.
  systemd.services.hermes-agent.serviceConfig = {
    ProtectHome = lib.mkForce true;
    AmbientCapabilities = "";
    CapabilityBoundingSet = "";
    LockPersonality = true;
    ProcSubset = "pid";
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    RemoveIPC = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallFilter = [ "@system-service" ];
    SystemCallErrorNumber = "EPERM";
  };

  sops.secrets = {
    # hermes-leo's own Buzz credential (default profile - read by the
    # gateway process directly via environmentFiles above). Codex/model
    # auth deliberately isn't here - see the settings.model comment above.
    hermes_leo_buzz_identity = {
      owner = "hermes";
      restartUnits = [ "hermes-agent.service" ];
    };

    # hermes-charlie's Forgejo token. Deliberately NOT wired into
    # services.hermes-agent.environmentFiles above - that option only
    # reaches the default profile (hermes-leo), and hermes-charlie is a
    # separate named profile per the authority-boundaries design. This
    # just lands the secret on disk, readable by the shared user; the
    # profile itself, and pointing its own config at this file, is a
    # one-time manual step (see below) - Hermes's per-profile credential
    # model is imperative, not something this module's options express.
    hermes_charlie_forgejo_token = {
      owner = "hermes";
    };
  };

  # One-time setup after first deploy (not expressible declaratively -
  # `hermes model`/`hermes profile create` and per-profile config are
  # imperative CLI operations against the already-running shared gateway):
  #
  #   sudo -u hermes HOME=/var/lib/hermes HERMES_HOME=/var/lib/hermes/.hermes hermes model
  #     (pick Codex/ChatGPT subscription, decline any CLI-import prompt,
  #     do a fresh device-code OAuth login - writes auth.json directly)
  #
  #   sudo -u hermes hermes profile create hermes-charlie
  #   sudo -u hermes hermes -p hermes-charlie config set <whatever
  #     key the Forgejo MCP/tool integration expects, pointed at
  #     /run/secrets/hermes_charlie_forgejo_token>
  #
  # Exact second command depends on which Forgejo integration mechanism
  # hermes-charlie ends up using (MCP server env var vs. a settings key) -
  # confirm against Hermes's own MCP server docs before running it for
  # real, don't guess the key name.
  #
  # hermes-charlie's own SOUL.md/AGENTS.md don't need a manual step at all:
  # the activation script below installs them declaratively, the same
  # install -D technique the module's own hermesHomeFiles/documents options
  # use internally (nix/moduleCommon.nix's installDocuments) - it's just
  # that those options are hardcoded to the default profile's paths, not a
  # fundamental limit of what Nix/activation scripts can reach. The only
  # genuinely imperative step left is `hermes profile create` itself (a
  # stateful CLI registration, not a file write) - run that once, and the
  # activation script below starts taking over SOUL.md/AGENTS.md from then
  # on, self-healing on every subsequent rebuild. Before that first
  # `profile create`, it's a harmless no-op (guarded on the profile
  # directory already existing).
  system.activationScripts."hermes-charlie-context-files" = {
    deps = [ "hermes-agent-setup" ];
    text =
      let
        profileDir = "${config.services.hermes-agent.stateDir}/.hermes/profiles/hermes-charlie";
      in
      ''
        if [ -d "${profileDir}" ]; then
          install -m 0640 -o hermes -g hermes -D ${./soul-charlie.md} "${profileDir}/SOUL.md"
          install -m 0640 -o hermes -g hermes -D ${./agents-charlie.md} "${profileDir}/workspace/AGENTS.md"
        fi
      '';
  };
}
