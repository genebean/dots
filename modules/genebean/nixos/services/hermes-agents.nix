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
            in
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (relPath: src: ''
                # HERMES_HOME (.hermes/), not the state dir's own root -
                # hermesHomeFiles-installed ("overwrite") skills already
                # live at .hermes/skills/<name>/, confirmed live: this
                # was wrong before (containerStateDir, no .hermes/) and
                # the result was a seed-once skill that hermes-agent
                # could never actually see - Danny's "mutable copy"
                # silently wasn't the file being read at all.
                dest="${containerHermesHome}/${relPath}"
                if [ ! -e "$dest" ]; then
                  mkdir -p "$(dirname "$dest")"
                  cp ${src} "$dest"
                  # Nix store files are mode 444 - cp preserves that, and
                  # chown alone doesn't add a write bit. Without this, the
                  # whole point of seed-once (the agent can durably edit
                  # its own copy) silently doesn't hold: the file lands
                  # owned by hermes but still read-only to hermes.
                  # chown -R (not just the file) so the agent can also
                  # create new files/do an atomic rename-replace inside
                  # its own skill directory, not just edit this one file.
                  chmod 644 "$dest"
                  chown -R hermes:hermes "$(dirname "$dest")"
                fi
              '') files
            )
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

  # One cron-registration service per seed-once skill, mirroring
  # daily-report-cron.nix's own proven idempotent (skip-if-present,
  # exact Name: field match) pattern - see that file for why a loose
  # substring match isn't good enough. Weekly only, via the gateway's
  # own always-on ticker - no deploy-triggered immediate-fire mechanism
  # (tried and dropped: every variant hit a different hermes-agent
  # quirk live - a boot-blocking synchronous `cron run`, `cron run`
  # silently not doing anything even once detached, then a missing-
  # secrets problem once dispatched directly - not worth the fragility
  # for a "sooner than a week" nicety when the weekly path alone is
  # already proven reliable).
  mkReconciliationServices =
    agentName: agentCfg:
    let
      hermesBin = "${hermesPkg}/bin/hermes";
      seedOnce = seedOnceSkills agentCfg;
    in
    lib.mapAttrs' (
      skillName: _skill:
      let
        jobName = "reconcile-${skillName}";
      in
      lib.nameValuePair "${jobName}-cron-setup" {
        description = "Register ${agentName}'s weekly ${skillName} reconciliation job (one-time)";
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
          ${hermesBin} cron create "0 17 * * 4" \
            "Reconcile the '${skillName}' skill per the rules-file-reconciliation skill, and report to #tradecraft." \
            --name ${jobName} \
            --skill rules-file-reconciliation
        '';
      }
    ) seedOnce;

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
      skillHomeFiles = overwriteSkillFiles agentCfg;
      envFileSecrets = lib.filterAttrs (_: secretCfg: secretCfg.envFileAs != null) agentCfg.secrets;
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
          ) agentCfg.secrets)
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
            environment.etc = seedOnceEtcFiles agentCfg;

            services.hermes-agent = {
              enable = true;

              addToSystemPackages = true;

              documents."AGENTS.md" = agentCfg.agentsFile;

              environment = {
                BUZZ_RELAY_URL = "https://buzz.home.technicalissues.us";
                BUZZ_CLI_PATH = "${pkgs.buzz-cli}/bin/buzz";
                BUZZ_ALLOW_ALL_USERS = "true";
              }
              // agentCfg.environment;

              environmentFiles =
                lib.mapAttrsToList (secretName: _: "/run/secrets/${secretName}") (
                  lib.filterAttrs (_: secretCfg: secretCfg.toEnvironmentFile) agentCfg.secrets
                )
                ++ lib.mapAttrsToList (secretName: _: "/run/secrets/${secretName}-envfile") envFileSecrets;

              extraPackages = [
                pkgs.buzz-cli
              ]
              ++ lib.optional agentCfg.enableGit pkgs.git
              ++ lib.optional needsTea pkgs.tea
              ++ mkGithubAppWrappers agentCfg
              ++ agentCfg.extraPackages;

              hermesHomeFiles = {
                "SOUL.md" = agentCfg.soulFile;
              }
              // skillHomeFiles
              // reconciliationHomeFiles agentCfg
              // agentCfg.extraHermesHomeFiles;

              inherit (agentCfg) mcpServers;

              settings = lib.recursiveUpdate {
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
                mkForgejoLoginService agentCfg
                // mkGithubAppServices agentCfg
                // mkGitCredentialHelper agentName agentCfg
                // mkSeedOnceService agentName agentCfg
                // mkReconciliationServices agentName agentCfg
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
        secrets = lib.mapAttrs (_secretName: secretCfg: {
          inherit (secretCfg) sopsFile;
          restartUnits = [ "container@${agentName}.service" ];
        }) agentCfg.secrets;

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
