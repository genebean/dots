# NixOS companion for modules/genebean/home/services/hermes-agents.nix,
# which declares the real options (per this repo's own convention - see
# modules/genebean/README.md, "Home Manager is always the consumer
# declaration point"). This file reads the already-resolved home-manager
# value back and does all the actual system-level work: one systemd-nspawn
# container per agent, secrets, Forgejo/GitHub credential plumbing, skill
# materialization.
#
# Promotion of modules/hosts/nixos/tcan-left/hermes/container-builder.nix,
# per its own header comment ("promote ... once the option surface stops
# shifting"). Five call sites (leo, charlie, danny, cj, sam) now exist, and
# several pieces of real boilerplate were being hand-copied 3-5x with no
# reconciliation when one copy drifted or got a bug fix the others didn't
# (confirmed: C.J.'s container was missing skill-materialization entirely
# until it got copy-pasted in from scratch; Charlie's tea-login-setup still
# has the known config-file-existence bug the other two copies already
# fixed independently).
#
# What's a first-class option here: identity/container plumbing, secrets +
# their restartUnits wiring (previously hand-written per secret in
# tcan-left/hermes/default.nix), Forgejo tea-login (previously 3 near-
# identical copies), GitHub App installation-token minting (previously
# Sam-only, hand-written), declarative skill materialization (previously a
# hand-copied lib.filesystem.listFilesRecursive block per agent per
# skill), MCP server config (mcpServers - verbatim passthrough, same
# treatment as hermesSettings), env-shaped secret reshaping (secrets.
# <name>.envFileAs - generates the sops.templates entry + bind mount +
# environmentFiles wiring that used to be hand-written per agent), and
# extra per-agent NixOS modules inside the container
# (extraContainerModules).
#
# There is deliberately no NixOS-side escape hatch (no agent default.nix
# setting containers.<name>.config.* directly) even for something only one
# agent currently needs - home-manager is the one consumer-declaration
# point (modules/genebean/README.md) and this file is the only place that
# turns those declarations into containers.<name>.*. A need that's
# genuinely agent-specific becomes a value passed through one of the
# options above (mcpServers, extraContainerModules, etc.), not a new file
# under tcan-left/hermes/<agent>/default.nix.
{
  config,
  lib,
  pkgs,
  inputs,
  username,
  hermesAgentNames,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.hermesAgents;

  # Fixed container-internal convention, not read back from the nested
  # config (would be circular - this file builds containers.${agentName}
  # while already needing a value derived from it). Matches
  # services.hermes-agent's own stateDir default, already relied on
  # elsewhere in this file as the bind-mount target below.
  containerStateDir = "/var/lib/hermes";
  containerHermesHome = "${containerStateDir}/.hermes";

  # agents-beads-collaboration-62h (self-improvement rules-file
  # mechanism): the fleet-wide authority doc every seed-once skill's
  # reconciliation pass reads, and the shared skill that does the actual
  # diffing/reporting. Both live here, not under any one host's hermes/
  # directory, because they're generic across every agent, not tcan-left-
  # specific.
  selfEditAuthorityPath = ./hermes-skills/self-edit-authority.md;
  reconciliationSkillSource = ./hermes-skills/rules-file-reconciliation;

  # The flake's own published package, not read back from any nested
  # container config (same circularity reasoning as containerStateDir
  # above) - this is what services.hermes-agent.package itself defaults
  # to, just reached from the outside.
  hermesPkg = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Same package every other dolt-beads client in this flake is actually
  # built against (bead-me-up-scotty.nix, modules/shared/home/general/
  # default.nix) - nixpkgs-unstable, not the stable channel's older bd.
  unstablePkgs = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  beadsPkg = unstablePkgs.beads;

  # Static per-agent metadata.json, seeded once rather than through a
  # live `bd init` - same proven approach as bead-me-up-scotty.nix (see
  # that file's header for why: bd init --global has not reliably
  # applied --global's beads_global database override, which otherwise
  # bootstraps a throwaway empty database every time, needing a manual
  # DROP DATABASE afterward - hit repeatedly during this effort's mr-c
  # rollout). No dolt_server_port (deprecated fallback field - the
  # BEADS_DOLT_SERVER_PORT env var below is the non-deprecated
  # equivalent) and no project_id: bd fills that in itself on first
  # successful connection when the field is simply absent (only an
  # actively wrong project_id - the --global bug's actual failure mode -
  # trips the identity-mismatch check).
  mkBeadsMetadataFile =
    agentName:
    pkgs.writeText "${agentName}-beads-metadata.json" (
      builtins.toJSON {
        database = "dolt";
        backend = "dolt";
        dolt_mode = "server";
        dolt_server_host = "dolt-beads.home.technicalissues.us";
        dolt_server_user = agentName;
        dolt_database = "beads_global";
      }
    );

  mkBeadsSeedService =
    agentName: agentCfg:
    lib.optionalAttrs (!agentCfg.beadsAccess) {
      # Env vars, the secret bind-mount, networking.extraHosts, the beads
      # package, and this very unit's own definition are all already
      # gated on beadsAccess and disappear on their own once it's false -
      # Nix's declarative model handles that for free. What it can't
      # undo is the data this service itself wrote imperatively while
      # beadsAccess was true - same reasoning tmpfiles.rules' own `d`
      # directive never deletes files it once created. This is the
      # counterpart: runs every activation (not seed's "only if
      # absent"), removing the directory if still present. Low-risk to
      # automate - it's just a connection pointer (host/user/database
      # name), never real coordination data, which lives on the Dolt
      # server itself, not here.
      beads-cleanup = {
        description = "Remove ${agentName}'s Beads workspace data (beadsAccess is false)";
        wantedBy = [ "multi-user.target" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          rm -rf "${containerStateDir}/beads"
        '';
      };
    }
    // lib.optionalAttrs agentCfg.beadsAccess {
      beads-metadata-seed = {
        description = "Seed ${agentName}'s Beads workspace metadata (only if absent)";
        wantedBy = [ "multi-user.target" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          beadsRoot="${containerStateDir}/beads"
          dir="$beadsRoot/.beads"
          mkdir -p "$dir"
          # A plain git config --global beads.role doesn't satisfy bd's own
          # check here - confirmed live (Leo, 2026-10-20): it worked for
          # gene/claude-rp's main workspace (already a real git repo) but
          # not for this bare directory. bd's config resolution appears to
          # require an actual repo to exist before it'll consult config at
          # all, global included - git init once (idempotent) and set it
          # locally instead, matching the upstream fix message's own
          # wording ("git config beads.role maintainer", no --global).
          #
          # -c safe.directory=... (not a persisted global safe.directory
          # add): this service runs as root, but $beadsRoot is hermes-
          # owned after the chown below runs on any prior invocation -
          # git's own dubious-ownership check (CVE-2022-24765) then
          # refuses every git command here except init itself, confirmed
          # live ("fatal: detected dubious ownership"). A one-shot -c
          # override needs no $HOME and leaves nothing to clean up later.
          if [ ! -d "$beadsRoot/.git" ]; then
            ${pkgs.git}/bin/git -c safe.directory="$beadsRoot" -C "$beadsRoot" init -q
            ${pkgs.git}/bin/git -c safe.directory="$beadsRoot" -C "$beadsRoot" config beads.role maintainer
          fi
          if [ ! -s "$dir/metadata.json" ]; then
            install -m 0644 ${mkBeadsMetadataFile agentName} "$dir/metadata.json"
          fi
          chown -R hermes:hermes "$beadsRoot"
          # bd's own recommended mode - confirmed live this warns otherwise
          # (mkdir's default mode, 0755, isn't tightened by anything else
          # in this path).
          chmod 700 "$dir"
        '';
      };
    };

  # ── Per-agent derivation of the container config ──────────────────────

  mkManagedSkillFiles =
    skillName: skill:
    lib.listToAttrs (
      map (p: {
        name = "skills/${skillName}/${builtins.unsafeDiscardStringContext (lib.removePrefix "${toString skill.source}/" (toString p))}";
        value = p;
      }) (lib.filesystem.listFilesRecursive skill.source)
    );

  # Same file set as mkManagedSkillFiles, but destined for
  # environment.etc rather than HERMES_HOME - the root-owned, read-only
  # reference copy a seed-once skill's mutable copy gets diffed against.
  # "zero custom activation code needed - a symlink into the Nix store,
  # always current on every deploy" (per the original design note).
  mkEtcSkillFiles =
    skillName: skill:
    lib.listToAttrs (
      map (p: {
        name = "hermes-skills/${skillName}/${builtins.unsafeDiscardStringContext (lib.removePrefix "${toString skill.source}/" (toString p))}";
        value = {
          source = p;
        };
      }) (lib.filesystem.listFilesRecursive skill.source)
    );

  # "overwrite" skills materialize through hermesHomeFiles exactly like
  # today. "seed-once" skills are NOT installed that way (that path is
  # unconditional `install -D` every activation, confirmed via
  # hermes-agent's own moduleCommon.nix - no existing "if absent" toggle
  # for it) - instead each one gets a single shared per-agent activation
  # guard below that copies file-by-file, only when the destination is
  # missing.
  overwriteSkillFiles =
    agentCfg:
    lib.foldl' lib.recursiveUpdate { } (
      lib.mapAttrsToList (
        skillName: skill:
        if skill.installMode == "overwrite" then mkManagedSkillFiles skillName skill else { }
      ) agentCfg.managedSkills
    );

  seedOnceSkills =
    agentCfg: lib.filterAttrs (_: skill: skill.installMode == "seed-once") agentCfg.managedSkills;

  mkSeedOnceService =
    agentName: agentCfg:
    let
      seedOnce = seedOnceSkills agentCfg;
    in
    lib.optionalAttrs (seedOnce != { }) {
      "seed-once-skills" = {
        description = "Seed ${agentName}'s seed-once skill files (only if absent)";
        wantedBy = [ "multi-user.target" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = lib.concatStringsSep "\n" (
          [ "set -euo pipefail" ]
          ++ lib.mapAttrsToList (
            skillName: skill:
            let
              files = mkManagedSkillFiles skillName skill;
              skillDir = "${containerHermesHome}/skills/${skillName}";
            in
            ''
              # HERMES_HOME (.hermes/), not the state dir's own root -
              # hermesHomeFiles-installed ("overwrite") skills already
              # live at .hermes/skills/<name>/, confirmed live: this
              # was wrong before (containerStateDir, no .hermes/) and
              # the result was a seed-once skill that hermes-agent
              # could never actually see - Danny's "mutable copy"
              # silently wasn't the file being read at all.
              ${lib.concatStringsSep "\n" (
                lib.mapAttrsToList (relPath: src: ''
                  dest="${containerHermesHome}/${relPath}"
                  if [ ! -e "$dest" ]; then
                    mkdir -p "$(dirname "$dest")"
                    cp ${src} "$dest"
                  fi
                '') files
              )}
              # Unconditional, every activation - NOT just inside the
              # "if absent" branch above. Confirmed live: a skill that
              # was "overwrite" mode before switching to seed-once
              # already had its directory tree on disk (installed as
              # root by hermesHomeFiles' own mechanism, which only
              # chowns the FILE, not the parent directories it
              # creates) - the "if absent" copy never ran for it, so
              # the one-time chmod/chown this used to do inline never
              # applied either, and the agent genuinely could not
              # write there (confirmed via a live `touch`: Permission
              # denied on the directory itself, even though the file
              # inside looked writable). Re-asserting ownership and
              # write access on the whole directory tree every
              # activation - cheap, idempotent, and the only way this
              # also self-heals a skill that was already stale before
              # this fix existed, not just newly-created ones going
              # forward.
              chown -R hermes:hermes "${skillDir}"
              find "${skillDir}" -type d -exec chmod u+rwx,g+rwx {} +
              find "${skillDir}" -type f -exec chmod u+rw,g+r {} +
            ''
          ) seedOnce
        );
      };
    };

  # Read-only reference copies (environment.etc) for every seed-once
  # skill this agent has - what its mutable copy gets diffed against.
  seedOnceEtcFiles =
    agentCfg:
    lib.foldl' lib.recursiveUpdate { } (
      lib.mapAttrsToList (skillName: skill: mkEtcSkillFiles skillName skill) (seedOnceSkills agentCfg)
    );

  # The shared reconciliation skill itself, only materialized for agents
  # that actually have something to reconcile - always-fresh (not
  # seed-once), this is the official mechanism, not anyone's own notes.
  reconciliationHomeFiles =
    agentCfg:
    lib.optionalAttrs (seedOnceSkills agentCfg != { }) (
      mkManagedSkillFiles "rules-file-reconciliation" { source = reconciliationSkillSource; }
    );

  # One cron-registration service per AGENT, not per skill - mirrors
  # daily-report-cron.nix's own proven idempotent (skip-if-present,
  # exact Name: field match) pattern, see that file for why a loose
  # substring match isn't good enough. Weekly only, via the gateway's
  # own always-on ticker - no deploy-triggered immediate-fire mechanism
  # (tried and dropped: every variant hit a different hermes-agent
  # quirk live - a boot-blocking synchronous `cron run`, `cron run`
  # silently not doing anything even once detached, then a missing-
  # secrets problem once dispatched directly - not worth the fragility
  # for a "sooner than a week" nicety when the weekly path alone is
  # already proven reliable).
  #
  # One job covering every seed-once skill an agent has, not one job
  # per skill: the prompt below doesn't name any skill - the skill's
  # own instructions have the agent enumerate /etc/hermes-skills/
  # itself to find the full set to reconcile this run. That keeps this
  # a single weekly LLM session per agent regardless of how many
  # seed-once skills they accumulate (was one session per skill before
  # 2026-10-17, which doesn't scale once seed-once became the default
  # install mode), and means adding or removing a seed-once skill never
  # requires touching this registered job - it stays correct on its
  # own.
  mkReconciliationServices =
    agentName: agentCfg:
    let
      hermesBin = "${hermesPkg}/bin/hermes";
      jobName = "reconcile-skills";
    in
    lib.optionalAttrs (seedOnceSkills agentCfg != { }) {
      "${jobName}-cron-setup" = {
        description = "Register ${agentName}'s weekly skill-reconciliation job (one-time)";
        wantedBy = [ "multi-user.target" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "hermes";
          Group = "hermes";
          Environment = "HERMES_HOME=${containerHermesHome}";
        };
        script = ''
          set -euo pipefail
          existing_ids=$(${hermesBin} cron list --all 2>/dev/null | ${pkgs.gawk}/bin/awk -v name="${jobName}" '
            /^  [0-9a-f]+ \[/ { id = $1 }
            $1 == "Name:" && $2 == name { print id }
          ')
          if [ -n "$existing_ids" ]; then
            exit 0
          fi
          ${hermesBin} cron create "${agentCfg.reconciliationSchedule}" \
            "Reconcile your seed-once skills per the rules-file-reconciliation skill, and report to #tradecraft." \
            --name ${jobName} \
            --skill rules-file-reconciliation
        '';
      };
    };

  # `tea logins add` (mkForgejoLoginService below) only registers a login
  # for tea's own REST-API client - it does nothing for plain `git clone`/
  # `push` over HTTPS, which several agents' own skills
  # (file-newspaper-article) actually shell out to directly. Confirmed
  # live (Danny, 2026-10-21): git config --global --list came back
  # completely empty - there was never a credential helper here at all,
  # cron or not; any past successful push was the agent improvising, not
  # a real mechanism. A separate writeShellScriptBin wrapper (not an
  # inline `git config --global credential.<url>.helper "!echo
  # password=$token"`) matters here specifically: git persists whatever
  # string you hand that option verbatim to ~/.gitconfig, so embedding
  # $token directly would bake the live secret in plaintext on disk the
  # moment the setup script's own shell expanded it - this wrapper reads
  # the secret file fresh every time git actually invokes it instead,
  # same pattern already proven for Sam's GitHub credential helper.
  mkForgejoGitCredentialHelper =
    agentName: agentCfg:
    lib.optionalAttrs (agentCfg.forgejoLogin != null) (
      let
        helper = pkgs.writeShellScriptBin "${agentName}-forgejo-git-credential-helper" ''
          set -euo pipefail
          if [ "''${1:-}" != "get" ]; then
            exit 0
          fi
          secret_file=/run/secrets/${agentCfg.forgejoLogin.tokenSecretName}
          token=$(${pkgs.gnused}/bin/sed -n 's/^FORGEJO_TOKEN=//p' "$secret_file")
          if [ -z "$token" ]; then
            token=$(cat "$secret_file")
          fi
          # Forgejo/Gitea's documented HTTP token auth doesn't validate
          # the username field, only the password/token - any non-empty
          # placeholder works here.
          echo "username=git"
          echo "password=$token"
        '';
      in
      {
        forgejo-git-credential-helper-setup = {
          description = "Configure ${agentName}'s git credential helper for Forgejo (one-time)";
          wantedBy = [ "multi-user.target" ];
          before = [ "hermes-agent.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "hermes";
            Group = "hermes";
            Environment = "HOME=/var/lib/hermes";
          };
          script = ''
            set -euo pipefail
            ${pkgs.git}/bin/git config --global credential.${agentCfg.forgejoLogin.url}.helper \
              "!${helper}/bin/${agentName}-forgejo-git-credential-helper"
          '';
        };
      }
    );

  mkForgejoLoginService =
    agentCfg:
    lib.optionalAttrs (agentCfg.forgejoLogin != null) {
      tea-login-setup = {
        description = "Register this agent's Forgejo token with tea (idempotent)";
        wantedBy = [ "multi-user.target" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          secret_file=/run/secrets/${agentCfg.forgejoLogin.tokenSecretName}
          token=$(${pkgs.gnused}/bin/sed -n 's/^FORGEJO_TOKEN=//p' "$secret_file")
          if [ -z "$token" ]; then
            token=$(cat "$secret_file")
          fi
          HOME=/var/lib/hermes ${pkgs.tea}/bin/tea logins delete --name forgejo 2>/dev/null || true
          HOME=/var/lib/hermes ${pkgs.tea}/bin/tea logins add \
            --name forgejo --url ${agentCfg.forgejoLogin.url} --token "$token" --no-version-check
          chown -R hermes:hermes /var/lib/hermes/.config
        '';
      };
    };

  mkGithubAppServices =
    agentCfg:
    lib.mapAttrs' (
      appName: app:
      lib.nameValuePair "github-app-token-refresh-${appName}" {
        description = "Mint installation token for GitHub App '${appName}'";
        wantedBy = [ "multi-user.target" ];
        before = [ "hermes-agent.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          key_path=/run/secrets/${app.keySecretName}
          token_file=/run/github-app-token-${appName}
          installation_id=$(${pkgs.gh-token}/bin/gh-token installations \
            --key "$key_path" --app-id ${app.appId} | ${pkgs.jq}/bin/jq -r '.[0].id')
          token=$(${pkgs.gh-token}/bin/gh-token generate \
            --key "$key_path" --app-id ${app.appId} \
            --installation-id "$installation_id" | ${pkgs.jq}/bin/jq -r '.token')
          tmpfile=$(${pkgs.coreutils}/bin/mktemp "$token_file".XXXXXX)
          printf '%s' "$token" > "$tmpfile"
          ${pkgs.coreutils}/bin/chown hermes:hermes "$tmpfile"
          ${pkgs.coreutils}/bin/chmod 0440 "$tmpfile"
          ${pkgs.coreutils}/bin/mv -f "$tmpfile" "$token_file"

          # systemctl restart, not start - start is a no-op on an already-
          # active Type=oneshot+RemainAfterExit=true unit (dots issue 797).
          # PID-suffixed unit name avoids a same-named reschedule collision
          # being silently swallowed by `|| true` (dots issue 798).
          ${pkgs.systemd}/bin/systemd-run --on-active=${toString app.refreshIntervalSeconds} --collect \
            --unit=github-app-token-refresh-${appName}-reschedule-$$ \
            --description="Reschedule GitHub App '${appName}' token refresh" \
            ${pkgs.systemd}/bin/systemctl restart github-app-token-refresh-${appName}.service || true
        '';
      }
    ) agentCfg.githubApps;

  mkGithubAppTimers =
    agentCfg:
    lib.mapAttrs' (
      appName: _app:
      lib.nameValuePair "github-app-token-refresh-${appName}" {
        description = "Refresh GitHub App '${appName}' installation token before it expires (backstop)";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/45";
          Persistent = true;
        };
      }
    ) agentCfg.githubApps;

  mkGithubAppWrappers =
    agentCfg:
    lib.mapAttrsToList (
      appName: app:
      pkgs.writeShellScriptBin app.wrapperName ''
        set -euo pipefail
        token=$(cat /run/github-app-token-${appName})
        GH_TOKEN="$token" exec ${pkgs.gh}/bin/gh "$@"
      ''
    ) agentCfg.githubApps;

  gitCredentialHelperApp =
    agentCfg: lib.findFirst (app: app.gitCredentialHelper) null (lib.attrValues agentCfg.githubApps);

  mkGitCredentialHelper =
    agentName: agentCfg:
    let
      app = gitCredentialHelperApp agentCfg;
    in
    lib.optionalAttrs (app != null) (
      let
        helper = pkgs.writeShellScriptBin "${agentName}-git-credential-helper" ''
          set -euo pipefail
          if [ "''${1:-}" != "get" ]; then
            exit 0
          fi
          token=$(cat /run/github-app-token-${
            lib.findFirst (n: agentCfg.githubApps.${n}.gitCredentialHelper) "" (
              lib.attrNames agentCfg.githubApps
            )
          })
          echo "username=x-access-token"
          echo "password=$token"
        '';
      in
      {
        git-credential-helper-setup = {
          description = "Configure ${agentName}'s git credential helper for github.com (one-time)";
          wantedBy = [ "multi-user.target" ];
          before = [ "hermes-agent.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "hermes";
            Group = "hermes";
            Environment = "HOME=/var/lib/hermes";
          };
          script = ''
            set -euo pipefail
            ${pkgs.git}/bin/git config --global credential.helper \
              "!${helper}/bin/${agentName}-git-credential-helper"
          '';
        };
      }
    );

  mkAgentContainer =
    agentName: agentCfg:
    let
      hostTimeZone = config.time.timeZone;
      # The container's nested NixOS evaluation builds its own fresh pkgs
      # by default and doesn't inherit the host's overlays (buzz-cli,
      # etc.) - bound under a distinct name before the inner `config`
      # function below introduces its own same-named `pkgs` argument, so
      # `nixpkgs.pkgs = hostPkgs;` references the host's pkgs rather than
      # the circular "whatever nixpkgs.pkgs resolves to" self-reference.
      hostPkgs = pkgs;
      needsTea = agentCfg.forgejoLogin != null;
      # sharedSkills is just a list of names (enum-typed, see the home-
      # manager option) - this resolves each to its actual source path
      # internally, the one place in the whole module that needs to
      # know hermes-skills/'s own directory layout, so no host-specific
      # agent home.nix ever has to reach into genebean/'s internals
      # with a relative path to use one.
      sharedSkillSources = {
        buzz-multipart-delivery = ./hermes-skills/buzz-multipart-delivery;
        newspaper-access = ./hermes-skills/newspaper-access;
        scheduled-publication-workflows = ./hermes-skills/scheduled-publication-workflows;
      };
      # Only overwriteSkillFiles/seedOnceSkills (both read only
      # .managedSkills off whatever's passed in) and
      # mkReconciliationServices (also reads .reconciliationSchedule)
      # ever see this merged value - every other agentCfg.foo reference
      # in this function still reads the real, unmerged option value
      # directly.
      skillsAgentCfg = {
        managedSkills =
          (lib.genAttrs agentCfg.sharedSkills (name: {
            source = sharedSkillSources.${name};
            installMode = "seed-once";
          }))
          // lib.optionalAttrs agentCfg.beadsAccess {
            # Not in sharedSkillSources/the sharedSkills enum - every
            # agent with beadsAccess gets this automatically, matching
            # that option's own default-true, no per-agent opt-in
            # needed (same reasoning as fleetWideSecrets above).
            beads-usage = {
              source = ./hermes-skills/beads-usage;
              installMode = "seed-once";
            };
          }
          // agentCfg.managedSkills;
        inherit (agentCfg) reconciliationSchedule;
      };
      skillHomeFiles = overwriteSkillFiles skillsAgentCfg;
      # Every agent, unconditionally - same tier as the environment
      # defaults below (BUZZ_RELAY_URL etc.). Read-only basic-auth
      # credential for the newspaper site: all five agents should be
      # able to read published content, not just the ones that author
      # it. sopsFile defaults to modules/shared/secrets.yaml already,
      # same file this secret actually lives in.
      # Plain Nix attrsets, not NixOS-option values - unlike agentCfg.secrets
      # (which went through secretType's own submodule defaulting), these
      # need every field downstream code reads spelled out explicitly.
      fleetWideSecrets = {
        hermes_newspaper_basic_auth_creds = {
          sopsFile = ../../../shared/secrets.yaml;
          toEnvironmentFile = false;
          envFileAs = "NEWSPAPER_BASIC_AUTH";
        };
      };
      # Reuses the per-agent secret already created and provisioned on
      # the dolt-beads server for this effort (agents-beads-
      # collaboration-3kt) - bare-password value, reshaped into
      # BEADS_DOLT_PASSWORD=<value> the same way envFileAs handles every
      # other bare-token secret in this file.
      beadsSecrets = lib.optionalAttrs agentCfg.beadsAccess {
        "dolt_beads_${agentName}_password" = {
          envFileAs = "BEADS_DOLT_PASSWORD";
          sopsFile = ../../../shared/secrets.yaml;
          toEnvironmentFile = false;
        };
      };
      allSecrets = fleetWideSecrets // beadsSecrets // agentCfg.secrets;
      envFileSecrets = lib.filterAttrs (_: secretCfg: secretCfg.envFileAs != null) allSecrets;
      envFileTemplateName = secretName: "${agentName}-${secretName}-envfile";
    in
    {
      containers.${agentName} = {
        autoStart = true;

        bindMounts =
          (lib.mapAttrs' (
            secretName: _secretCfg:
            lib.nameValuePair "/run/secrets/${secretName}" {
              # The stable /run/secrets/<name> symlink, matching every
              # other secretBindMount in this fleet, rather than
              # config.sops.secrets.<name>.path - this module both reads
              # and writes sops.secrets, and reading the full merge back
              # from within the same contribution risks exactly the kind
              # of self-reference NixOS's module system can't always
              # resolve lazily.
              hostPath = "/run/secrets/${secretName}";
              isReadOnly = true;
            }
          ) allSecrets)
          // (lib.mapAttrs' (
            secretName: _secretCfg:
            lib.nameValuePair "/run/secrets/${secretName}-envfile" {
              hostPath = config.sops.templates.${envFileTemplateName secretName}.path;
              isReadOnly = true;
            }
          ) envFileSecrets)
          // {
            "/var/lib/hermes" = {
              hostPath = agentCfg.stateHostPath;
              isReadOnly = false;
            };
          };

        config =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          {
            imports = [ inputs.hermes-agent.nixosModules.default ] ++ agentCfg.extraContainerModules;

            system.stateVersion = agentCfg.stateVersion;

            nixpkgs.pkgs = hostPkgs;

            # Read-only reference copies for this agent's seed-once
            # skills - empty attrset (no-op) for every agent that has
            # none yet.
            environment.etc = seedOnceEtcFiles skillsAgentCfg;

            # tcan-left is a different host from nixnuc (where dolt-beads
            # actually runs) and this is a separate per-container
            # filesystem regardless of network-namespace sharing
            # (privateNetwork = false below just means shared host
            # networking, not a shared /etc/hosts) - real LAN IP, not
            # loopback, same reasoning as bead-me-up-scotty.nix's own
            # --add-host fix.
            networking.extraHosts = lib.optionalString agentCfg.beadsAccess ''
              192.168.20.190 dolt-beads.home.technicalissues.us
            '';

            services.hermes-agent = {
              enable = true;

              addToSystemPackages = true;

              documents."AGENTS.md" = agentCfg.agentsFile;

              environment = {
                BUZZ_RELAY_URL = "https://buzz.home.technicalissues.us";
                BUZZ_CLI_PATH = "${pkgs.buzz-cli}/bin/buzz";
                BUZZ_ALLOW_ALL_USERS = "true";
                # Paired with the fleet-wide NEWSPAPER_BASIC_AUTH secret
                # above - every agent can read published content, not
                # just the ones that author it. See the newspaper-access
                # skill (each agent's own managedSkills, seed-once - not
                # baked in here, since it's safety-net self-editable the
                # same as everything else, not infra plumbing) for usage.
                NEWSPAPER_URL = "https://newspaper.home.technicalissues.us";
              }
              // lib.optionalAttrs agentCfg.beadsAccess {
                BEADS_ACTOR = agentName;
                BEADS_DIR = "${containerStateDir}/beads/.beads";
                # Env var, not metadata.json's dolt_server_port field -
                # that's the deprecated fallback (see mkBeadsMetadataFile).
                BEADS_DOLT_SERVER_PORT = "3307";
                BEADS_DOLT_SERVER_TLS = "1";
                BEADS_DOLT_SERVER_USER = agentName;
              }
              // agentCfg.environment;

              environmentFiles =
                lib.mapAttrsToList (secretName: _: "/run/secrets/${secretName}") (
                  lib.filterAttrs (_: secretCfg: secretCfg.toEnvironmentFile) allSecrets
                )
                ++ lib.mapAttrsToList (secretName: _: "/run/secrets/${secretName}-envfile") envFileSecrets;

              extraPackages = [
                pkgs.buzz-cli
              ]
              ++ lib.optional agentCfg.beadsAccess beadsPkg
              ++ lib.optional agentCfg.enableGit pkgs.git
              ++ lib.optional needsTea pkgs.tea
              ++ mkGithubAppWrappers agentCfg
              ++ agentCfg.extraPackages;

              hermesHomeFiles = {
                "SOUL.md" = agentCfg.soulFile;
              }
              // skillHomeFiles
              // reconciliationHomeFiles skillsAgentCfg
              // agentCfg.extraHermesHomeFiles;

              inherit (agentCfg) mcpServers;

              # lib.recursiveUpdate overwrites lists rather than merging
              # them - if any agent's own hermesSettings ever sets its
              # own approvals.deny, it replaces this list entirely rather
              # than adding to it. None of the current 5 agents do; worth
              # re-checking this comment before any agent ever adds one.
              settings = lib.recursiveUpdate {
                approvals.deny = lib.optionals agentCfg.beadsAccess [
                  # hermes-agent's own hardline floor (approvals.deny) -
                  # enforced unconditionally, before --yolo/approvals.
                  # mode=off even get consulted. Backs the same three
                  # rules documented in the beads-usage skill with real
                  # enforcement instead of just prose: bd init has a
                  # known --global database-override bug (hit repeatedly
                  # standing up this fleet), bd edit opens an interactive
                  # editor and hangs, and --force on update/close exists
                  # specifically to override another actor's live claim
                  # or an unsatisfied blocker.
                  "*bd init*"
                  "*bd edit*"
                  "*bd update*--force*"
                  "*bd close*--force*"
                ];
                backend.mode = "none";
                gateway.platforms.buzz = {
                  enabled = true;
                  extra = {
                    poll_interval = 4;
                    require_mention = true;
                  };
                };
                display.platforms.buzz = {
                  interim_assistant_messages = false;
                  tool_progress = "off";
                };
              } agentCfg.hermesSettings;

              workingDirectory = "${config.services.hermes-agent.stateDir}/workspace";
            };

            systemd = {
              services =
                mkBeadsSeedService agentName agentCfg
                // mkForgejoGitCredentialHelper agentName agentCfg
                // mkForgejoLoginService agentCfg
                // mkGitCredentialHelper agentName agentCfg
                // mkGithubAppServices agentCfg
                // mkReconciliationServices agentName skillsAgentCfg
                // mkSeedOnceService agentName skillsAgentCfg
                // {
                  hermes-agent.serviceConfig = {
                    ProtectHome = lib.mkForce true;
                    AmbientCapabilities = "";
                    CapabilityBoundingSet = "";
                    LockPersonality = true;
                    ProcSubset = "pid";
                    ReadOnlyPaths = agentCfg.extraReadOnlyPaths;
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
                };

              timers = mkGithubAppTimers agentCfg;
            };

            time.timeZone = hostTimeZone;
          };

        privateNetwork = false; # outbound-only; never binds a port

        specialArgs = { inherit inputs; };
      };

      sops = {
        # allSecrets (not agentCfg.secrets): fleetWideSecrets' entries get
        # contributed by every agent's own call to this function -
        # NixOS's list-typed option merging (same as services.restic.
        # backups.daily.paths elsewhere in this file) collapses that into
        # one shared sops.secrets.<name> with every agent's
        # container@<name>.service in its restartUnits, one decrypted
        # file on the host, bind-mounted read-only into all of them.
        secrets = lib.mapAttrs (_secretName: secretCfg: {
          inherit (secretCfg) sopsFile;
          restartUnits = [ "container@${agentName}.service" ];
        }) allSecrets;

        # One reshaped KEY=value template per envFileAs secret - see that
        # option's own description. Never duplicates the secret's
        # encrypted value, just its on-disk shape.
        templates = lib.mapAttrs' (
          secretName: secretCfg:
          lib.nameValuePair (envFileTemplateName secretName) {
            content = "${secretCfg.envFileAs}=${config.sops.placeholder.${secretName}}";
            restartUnits = [ "container@${agentName}.service" ];
          }
        ) envFileSecrets;
      };

      systemd.tmpfiles.rules = [
        # 0755, not 0750 - the `d` directive re-enforces mode on every
        # systemd-tmpfiles-resetup run, not just on first creation, and a
        # tighter mode here blocked the container's own "hermes" user from
        # even traversing in (confirmed live, broke every agent on a
        # deploy that only touched one agent's files). Real access control
        # is each container's own deeper subdirectory permissions.
        "d ${agentCfg.stateHostPath} 0755 root root -"
      ]
      ++ lib.optionals (seedOnceSkills agentCfg != { }) [
        # At the state dir's own root, not inside .hermes/ (HERMES_HOME)
        # or workspace/ (documents) - this is deliberately a sibling of
        # both, so AGENTS.md's "../self-edit-authority.md" (one level up
        # from where `documents` installs it, into workspace/) resolves
        # correctly at runtime. L+ (not a seed-once `d`/copy): always a
        # fresh symlink into the Nix store, same "always current, no
        # custom activation code" treatment as environment.etc above -
        # this file is the official mechanism, never the agent's own.
        "L+ ${agentCfg.stateHostPath}/self-edit-authority.md - - - - ${selfEditAuthorityPath}"
      ];
    };

in
{
  # Do not replace the explicit roster with lib.attrNames cfg. Enumerating
  # the full key set of this Home Manager attrsOf option from the NixOS
  # module creates a module-system cycle. The host builder passes the names
  # as a specialArg derived from the same plain list as the Home Manager
  # imports. Accessing each cfg.${name} directly keeps evaluation lazy;
  # hosts using the default empty roster never force cfg.
  config = lib.mkMerge (
    (map (name: mkAgentContainer name cfg.${name}) hermesAgentNames)
    ++ [
      # Every agent's HERMES_HOME - memories, skills (bundled and any
      # seed-once mutable copies), session/cron/auth state - backed up by
      # default, unconditionally. Excludes cache/ and tools/
      # specifically: confirmed live on tcan-left these are large (2.3G
      # alone on one agent) and purely regenerable - downloaded tool
      # binaries and restic's own kind of local cache, not agent state.
      {
        services.restic.backups.daily = {
          paths = map (name: "${cfg.${name}.stateHostPath}/.hermes") hermesAgentNames;
          exclude = lib.concatMap (name: [
            "${cfg.${name}.stateHostPath}/.hermes/cache"
            "${cfg.${name}.stateHostPath}/.hermes/tools"
          ]) hermesAgentNames;
        };
      }
    ]
  );
}
