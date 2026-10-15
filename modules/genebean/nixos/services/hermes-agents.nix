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
  hostname,
  ...
}:
let
  cfg = config.home-manager.users.${username}.genebean.services.hermesAgents;

  # ── Per-agent derivation of the container config ──────────────────────

  mkManagedSkillFiles =
    skillName: skill:
    lib.listToAttrs (
      map (p: {
        name = "skills/${skillName}/${builtins.unsafeDiscardStringContext (lib.removePrefix "${toString skill.source}/" (toString p))}";
        value = p;
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
                dest="/var/lib/hermes/${relPath}"
                if [ ! -e "$dest" ]; then
                  mkdir -p "$(dirname "$dest")"
                  cp ${src} "$dest"
                  chown hermes:hermes "$dest"
                fi
              '') files
            )
          ) seedOnce
        );
      };
    };

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
      ];
    };

  # Static, not lib.attrNames cfg - confirmed live that enumerating the
  # full key set of an attrsOf option nested inside
  # config.home-manager.users.<name>.* from this (NixOS) side is
  # genuinely circular: even querying a totally unrelated leaf of the
  # overall system config recurses infinitely the moment any form of
  # full-key enumeration appears anywhere in this module's own `config`
  # output. Direct, single-key access (cfg.${name}) is unaffected - only
  # resolving "what are ALL the keys" is the problem. A new agent needs
  # a line added here, matching hermes/home.nix's own static imports
  # list for the same five agents.
  knownAgentNames = [
    "leo"
    "charlie"
    "danny"
    "cj"
    "sam"
  ];

  # Hosts that actually run any of these agents - today, just tcan-left.
  # Add a hostname here, not just a name to knownAgentNames, the day an
  # agent moves to or is added on a second host.
  agentHosts = [ "tcan-left" ];
in
{
  # Gated on `hostname`, not on probing cfg's own keys - this module
  # (nixosModules.genebean) is imported fleet-wide, not just by
  # tcan-left, and every other host has no agents defined at all
  # (cfg = {}). Confirmed live that EVERY form of "handle a possibly-
  # missing key safely" - `?`, `or`, attrNames, mapAttrsToList - is
  # circular here (see the comment on knownAgentNames above); only a
  # host-level `if`, which short-circuits before `cfg.${n}` is ever
  # forced at all on a host with no agents, actually avoids it.
  config =
    if !builtins.elem hostname agentHosts then
      { }
    else
      lib.mkMerge (map (n: mkAgentContainer n cfg.${n}) knownAgentNames);
}
