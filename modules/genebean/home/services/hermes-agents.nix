# Consumer-facing declaration point (see modules/genebean/README.md - "Home
# Manager is always the consumer declaration point"). Hermes agent
# containers are root-only system infrastructure with no actual per-user
# home-manager effect of their own - this module declares options and
# nothing else, matching the simple-enable-stub pattern's shape but with no
# `config` block at all. The NixOS companion
# (modules/genebean/nixos/services/hermes-agents.nix) reads this resolved
# value back and does all the real work (containers, secrets, systemd
# units) - see that file for what each option actually produces.
{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;

  forgejoUrlDefault = "https://git.home.technicalissues.us";

  secretType = types.submodule {
    options = {
      envFileAs = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          For a secret whose raw value is a bare token (not already
          KEY=value shaped) that still needs to land in the agent's
          environment under a specific variable name - e.g. shared as-is
          with some other service's own secret. When set, a
          sops.templates entry is generated that wraps the raw value into
          a single "<envFileAs>=<value>" line, and that template's path
          (not the raw secret) is bind-mounted into the container and
          added to services.hermes-agent.environmentFiles. Mutually
          exclusive with toEnvironmentFile in practice (the raw secret
          isn't itself env-shaped), though nothing enforces that here.
        '';
      };
      sopsFile = mkOption {
        type = types.path;
        default = ../../../shared/secrets.yaml;
        description = "sops file this secret lives in.";
      };
      toEnvironmentFile = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to add this secret's bind-mounted path to
          services.hermes-agent.environmentFiles (merged into the agent's
          own .env). Secrets consumed some other way (e.g. by a
          forgejoLogin or githubApps setup script, read directly from
          /run/secrets/<name>) should leave this false.
        '';
      };
    };
  };

  forgejoLoginType = types.submodule {
    options = {
      tokenSecretName = mkOption {
        type = types.str;
        description = ''
          Name of an entry in this agent's own `secrets` option holding
          the Forgejo token. Expected content: either a bare token, or a
          FORGEJO_TOKEN=<value> line (both are tolerated, matching every
          existing agent's secret today).
        '';
      };
      url = mkOption {
        type = types.str;
        default = forgejoUrlDefault;
        description = "Forgejo instance URL to log in against.";
      };
    };
  };

  githubAppType = types.submodule {
    options = {
      appId = mkOption {
        type = types.str;
        description = "GitHub App ID (not secret - same tier as a channel ID).";
      };
      keySecretName = mkOption {
        type = types.str;
        description = ''
          Name of an entry in this agent's own `secrets` option holding
          the App's private key (PEM). Never read by the agent's own
          process - only by this entry's own root-run minting service.
        '';
      };
      wrapperName = mkOption {
        type = types.str;
        description = ''
          Name of the generated wrapper command (pkgs.writeShellScriptBin)
          that sets GH_TOKEN from this entry's freshly-minted installation
          token and execs `gh`. Example: "sam-gh".
        '';
      };
      gitCredentialHelper = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether raw `git` operations against github.com HTTPS remotes
          should use this entry's token via a global credential helper.
          At most one githubApps entry per agent should set this true.
        '';
      };
      refreshIntervalSeconds = mkOption {
        type = types.int;
        default = 2700; # 45 minutes - installation tokens expire hourly
        description = "Self-reschedule interval for minting a fresh installation token.";
      };
    };
  };

  managedSkillType = types.submodule {
    options = {
      source = mkOption {
        type = types.path;
        description = "Directory this skill's files are recursively listed from.";
      };
      installMode = mkOption {
        type = types.enum [
          "overwrite"
          "seed-once"
        ];
        default = "seed-once";
        description = ''
          "seed-once" (default): installed only if the live path doesn't
          already exist, so the agent can edit its own copy durably
          across deploys. A root-owned, read-only reference copy is also
          materialized at /etc/hermes-skills/<name>/ inside the
          container, and the weekly rules-file-reconciliation skill
          (agents-beads-collaboration-62h) diffs every seed-once skill
          an agent has - one shared weekly session per agent, not one
          per skill - against that reference and reports drift to
          #tradecraft.

          "overwrite": materialized fresh from the Nix store on every
          activation; any live edit the agent makes to its own copy is
          lost on the next deploy that touches this container. Default
          until 2026-10-17, now the deliberate exception rather than the
          default: hermes-agent's own self-editing tools
          (skill_manage et al.) work on any file under
          $HERMES_HOME/skills/ regardless of how it got there, so
          "overwrite" doesn't actually prevent an agent from editing a
          skill - it just means that edit gets silently destroyed on
          the next deploy with no record, instead of being preserved
          and surfaced for review like seed-once does. Reach for this
          only when the reconciliation cost itself is the problem (a
          skill whose official source changes often enough that weekly
          drift review would be pure noise), not merely because a
          skill "shouldn't" need editing.
        '';
      };
    };
  };

  agentType = types.submodule (
    { name, ... }:
    {
      options = {
        stateVersion = mkOption {
          type = types.str;
          # No default, deliberately: a new agent should get the current
          # NixOS release, not silently inherit whatever this module's own
          # default happened to be when it was written - same reasoning
          # container-builder.nix already documented for this option.
          description = "system.stateVersion for this agent's nested NixOS evaluation.";
        };

        agentsFile = mkOption {
          type = types.path;
          description = "AGENTS.md for this agent.";
        };

        beadsAccess = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Wires this agent up as its own client of the shared
            agents-beads-collaboration Dolt/Beads server
            (dolt-beads.home.technicalissues.us), under its own identity
            (BEADS_ACTOR/BEADS_DOLT_SERVER_USER = this agent's name).
            Default true - every fleet agent gets this; set false on a
            specific agent to opt out. Reuses the already-provisioned
            dolt_beads_<name>_password secret and SQL identity
            (agents-beads-collaboration-3kt). Seeds a static
            metadata.json once (if absent) instead of running a live
            `bd init` - avoids the known `--global` database-override
            bug that otherwise bootstraps a throwaway empty database on
            every fresh init (hit repeatedly during this effort's own
            rollout).
          '';
        };

        enableGit = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Add pkgs.git to this agent's extraPackages. Default true -
            every fleet agent gets this; set false on a specific agent
            to opt out. Matters because this is the only path that
            reaches the agent's own real, interactive-shell PATH
            (/etc/profiles/per-user/hermes/bin) - hermes-agent's own
            base processPath unconditionally adds git to the hermes-
            agent.service UNIT's own PATH, but that doesn't propagate
            to the per-user profile the agent's own shell tool calls
            actually use (confirmed live, Leo, 2026-10-20: git present
            in the raw service env, absent from Leo's own `echo
            $PATH`/`which git`).
          '';
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Non-secret environment variables, merged over the shared defaults.";
        };

        extraContainerModules = mkOption {
          # types.raw, not types.anything: these list entries are often
          # raw NixOS module *functions* (e.g. a flake's nixosModules.
          # default), and types.anything's merge special-cases function-
          # shaped values (treats them as types.functionTo and tries to
          # merge-by-calling them) - confirmed live that this breaks a
          # curried flake module with "called without required argument
          # 'pkgs'". types.raw's merge (mergeOneOption) never introspects
          # the value at all.
          type = types.listOf types.raw;
          default = [ ];
          description = ''
            Extra NixOS modules merged into this agent's own
            containers.<name>.config.imports - for agent-specific
            functionality (a companion systemd timer/service, extra
            networking.hosts entries, etc.) that isn't itself a
            first-class hermesAgents option. Promote a pattern into a
            real option here once a second agent needs the same thing,
            not before.
          '';
        };

        extraHermesHomeFiles = mkOption {
          type = types.attrsOf types.path;
          default = { };
          description = ''
            One-off HERMES_HOME files that don't fit managedSkills (a
            private data file, a template, etc.) - "<relpath>" -> source
            path, merged alongside SOUL.md and every managedSkills entry.
          '';
        };

        extraPackages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages on this agent's PATH.";
        };

        extraReadOnlyPaths = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Container-internal paths hermes-agent.service may read beyond /var/lib/hermes.";
        };

        forgejoLogin = mkOption {
          type = types.nullOr forgejoLoginType;
          default = null;
          description = ''
            When set, generates an idempotent (delete-then-add) tea-login-
            setup service - registers a persistent `tea` login from the
            named secret before hermes-agent starts. Idempotent from the
            start: always delete-then-add, never gated on the config file
            already existing (that shape has a known bug -
            hermes-agent-fleet-plan#51 - a credential rotation silently
            has no effect once the file exists once).
          '';
        };

        githubApps = mkOption {
          type = types.attrsOf githubAppType;
          default = { };
          description = ''
            GitHub Apps this agent mints short-lived installation tokens
            from. Each entry gets its own self-rescheduling root-run
            minting service + OnCalendar backstop timer, writing only the
            derived, already-scoped, hour-lived token to a container-local
            tmpfs path readable by `hermes` - the agent's own process
            never touches the App's private key. Self-reschedule uses
            `systemctl restart` (not `start` - a no-op on an already-
            active Type=oneshot+RemainAfterExit=true unit) with a PID-
            suffixed transient unit name (avoids a same-named collision
            being silently swallowed) - both confirmed-necessary live,
            dots issues 797/798.
          '';
        };

        hermesSettings = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Merged over the shared services.hermes-agent.settings defaults.";
        };

        managedSkills = mkOption {
          type = types.attrsOf managedSkillType;
          default = { };
          description = ''
            Declarative skill materialization. Each attribute name becomes
            the skill's directory under HERMES_HOME (skills/<name>/...),
            recursively listed from its own `source` - a file added to the
            skill later is picked up automatically, no Nix change needed.
          '';
        };

        mcpServers = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = ''
            Passed through verbatim to this agent's own
            services.hermes-agent.mcpServers inside its container - see
            hermes-agent's own option for the full per-server schema (url,
            headers, tools.include/exclude, etc). Not validated here -
            attrsOf types.anything, same passthrough treatment as
            hermesSettings.
          '';
        };

        reconciliationSchedule = mkOption {
          type = types.str;
          default = "0 17 * * 4";
          description = ''
            Cron schedule (same syntax as `hermes cron create`'s own
            schedule argument) for this agent's weekly skill-
            reconciliation job - only registered at all if this agent has
            at least one seed-once skill (managedSkills or sharedSkills).
            Override per agent to stagger reconciliation across the
            fleet deliberately, rather than letting every agent's weekly
            session land at the same moment and overlap.

            Only affects *newly* registered jobs: the registration
            service is a one-time, skip-if-present setup (matches
            daily-report-cron.nix's own idempotent pattern) - changing
            this value does not update a schedule an agent already has
            registered. Delete the existing `reconcile-skills` cron job
            on that agent directly (`hermes cron delete <id>`) and
            redeploy to pick up a new schedule.
          '';
        };

        secrets = mkOption {
          type = types.attrsOf secretType;
          default = { };
          description = ''
            Secrets this agent needs. Each one gets: a host-side
            sops.secrets.<name> declaration (restartUnits auto-set to this
            agent's container@<name>.service), a bind mount at
            /run/secrets/<name> inside the container, and - if
            toEnvironmentFile is set - an entry in
            services.hermes-agent.environmentFiles.
          '';
        };

        sharedSkills = mkOption {
          type = types.listOf (
            types.enum [
              "buzz-multipart-delivery"
              "newspaper-access"
              "scheduled-publication-workflows"
            ]
          );
          default = [ ];
          description = ''
            Fleet-wide skills this agent should have, by name - opt in
            here rather than pointing `managedSkills.<name>.source` at
            modules/genebean/nixos/services/hermes-skills/<name>
            yourself. The whole point of the genebean/ namespace is that
            a host-specific file (this one) never needs to know that
            module's internal directory layout; the NixOS companion
            resolves each name to its own actual source path internally.
            Always seed-once (matches the default for managedSkills
            itself) - these are meant to be self-correctable the same
            way as anything else, not special-cased as unconditionally
            overwritten official content.
          '';
        };

        soulFile = mkOption {
          type = types.path;
          description = "SOUL.md for this agent.";
        };

        stateHostPath = mkOption {
          type = types.str;
          default = "/var/lib/hermes-containers/${name}";
          description = "Host path bind-mounted to the guest's /var/lib/hermes.";
        };
      };
    }
  );
in
{
  options.genebean.services.hermesAgents = mkOption {
    type = types.attrsOf agentType;
    default = { };
    description = ''
      Hermes agent containers (systemd-nspawn, one per agent, running
      services.hermes-agent in native mode as that container's only
      profile). Each attribute name is the agent's own name - matches
      the container name and, by extension, container@<name>.service.
      Declared here (not in nixos/) per this repo's own convention - see
      modules/genebean/README.md - even though the actual effect is
      entirely NixOS-side; the nixos/ companion does all the real work.
    '';
  };
}
