# One function, reused by every agent container under tcan-left/hermes/*.
# Deliberately a plain function, not a NixOS module with its own typed
# options - keeps each call site a normal, readable module instead of
# hiding agent-specific config behind indirection. Promote to
# modules/genebean/nixos/ once the option surface stops shifting; three
# call sites exist today (Leo, Charlie, Danny) but each new one has
# still been adding a genuinely new parameter (extraHermesHomeFiles most
# recently), not just reusing the existing surface - a typed module would
# still be guessing at the abstraction boundary.
#
# Each agent is its own systemd-nspawn container running services.hermes-agent
# in native mode (container.enable = false, the module's own default - not
# its unrelated OCI/podman self-modifying-sandbox feature) as that
# container's only profile. No multiplexed profiles, no imperative
# `hermes profile create` step, no activation-script workaround for a
# second profile's files - every agent is declared the same way.
#
# Secrets: this function never imports sops-nix into the guest. The host
# (tcan-left, via hermes/default.nix) decrypts each secret normally via its
# own sops.secrets.<name>, then the call site bind-mounts that single
# decrypted file into the guest at environmentFiles's own path. The guest
# never needs its own age identity.
{
  inputs,
  hostPkgs, # the host's own already-overlaid pkgs (nixpkgs-settings.nix's
  # buzz-cli entry, etc.) - a container's nested NixOS evaluation builds its
  # own fresh pkgs by default and doesn't inherit the host's overlays, so
  # this gets threaded through via nixpkgs.pkgs below instead.
  hostTimeZone, # the host's own config.time.timeZone - a container's nested
  # evaluation doesn't inherit it either (defaults to UTC), and every
  # agent's logs/timers should read in the same zone as the host they
  # actually run on, not wherever the flake happened to default.
}:
{
  name,
  soulFile,
  agentsFile,
  stateHostPath, # host path bind-mounted to the guest's /var/lib/hermes
  stateVersion, # required, not defaulted - a new agent should get the
  # current release, not silently inherit whatever this
  # function's own default happened to be when it was written
  secretBindMounts ? { }, # "/run/secrets/<name>" -> host decrypted-secret path
  environment ? { }, # non-secret env (BUZZ_RELAY_URL, etc.)
  environmentFiles ? [ ], # plain string paths - matches secretBindMounts' keys
  hermesSettings ? { }, # merged over the shared defaults below
  extraPackages ? [ ],
  extraHermesHomeFiles ? { }, # "<relpath under HERMES_HOME>" -> source path;
  # merged alongside SOUL.md below. A real Nix option (drives activation-
  # time file materialization), unlike hermesSettings - never put a skill
  # or any other HERMES_HOME file under hermesSettings, it only reaches
  # the agent's own free-form settings.yaml, not the filesystem.
}:
{
  # systemd-nspawn does not create bind-mount source directories itself -
  # confirmed the hard way ("Failed to clone <path>: No such file or
  # directory") when this was missing. Content/ownership of the directory's
  # CONTENTS is still the container's own job (its activation script runs
  # as root inside, same UID 0 as the host since privateUsers isn't set,
  # and chowns its own subtree to whatever "hermes" UID it allocates) -
  # this only needs to guarantee the mount source exists at all.
  #
  # 0755, not 0750: the `d` tmpfiles directive re-enforces mode/ownership
  # on every systemd-tmpfiles-resetup.service run (not just on first
  # creation), which fires on every deploy that touches sops secrets.
  # 0750 root:root blocked the container's own "hermes" user (not a
  # member of the host's root group) from even traversing into this
  # directory, breaking every agent - not just the one whose own config
  # changed - on every deploy, discovered the hard way when Leo and
  # Charlie broke from a deploy that only touched Danny's files. The
  # deeper subdirectories' own tighter permissions (2770 hermes:hermes,
  # set by each container's own activation) are the real access control;
  # this directory only needs to exist and be traversable.
  systemd.tmpfiles.rules = [
    "d ${stateHostPath} 0755 root root -"
  ];

  containers.${name} = {
    autoStart = true;
    privateNetwork = false; # outbound-only (Buzz relay, Forgejo/GitHub, LLM
    # API); never binds a port, so no genebean.ports entry needed
    specialArgs = { inherit inputs; };

    bindMounts = secretBindMounts // {
      "/var/lib/hermes" = {
        hostPath = stateHostPath;
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
        nixpkgs.pkgs = hostPkgs;
        system.stateVersion = stateVersion;
        time.timeZone = hostTimeZone;

        imports = [ inputs.hermes-agent.nixosModules.default ];

        services.hermes-agent = {
          enable = true;

          # Exports the `hermes` CLI + HERMES_HOME to interactive shells -
          # useful for one-time setup (e.g. `hermes model` login) via
          # `machinectl shell <name>`.
          addToSystemPackages = true;

          extraPackages = [ pkgs.buzz-cli ] ++ extraPackages;

          hermesHomeFiles = {
            "SOUL.md" = soulFile;
          }
          // extraHermesHomeFiles;

          workingDirectory = "${config.services.hermes-agent.stateDir}/workspace";
          documents."AGENTS.md" = agentsFile;

          environment = {
            BUZZ_RELAY_URL = "https://buzz.home.technicalissues.us";
            # Resolved explicitly rather than left to `shutil.which("buzz")`
            # on PATH (plugins/platforms/buzz/adapter.py's standalone/cron
            # send path, `_resolve_cli_path`) - confirmed that lookup only
            # sees whichever process's own PATH is in effect, which is NOT
            # the same for every caller (hermes-agent.service's PATH
            # includes buzz-cli from this same extraPackages list; an
            # interactive `machinectl shell` root session does not, and
            # failed cron delivery with "buzz CLI binary not found" when
            # testing issue 41's daily-social-report job from one). An
            # absolute path sidesteps that PATH-dependence entirely.
            BUZZ_CLI_PATH = "${pkgs.buzz-cli}/bin/buzz";
            # Every agent allows any relay member to talk to it - caution
            # and reporting-structure judgment (e.g. Charlie only acting on
            # Leo's instructions) lives in each agent's own AGENTS.md, not
            # a technical allow-list. Without this, hermes-agent's
            # authz_mixin defaults to deny-all once BUZZ_ALLOWED_USERS is
            # unset (gateway/authz_mixin.py's _principal_authorized) - this
            # has to be set, not just absent.
            BUZZ_ALLOW_ALL_USERS = "true";
          }
          // environment;
          inherit environmentFiles;

          settings = lib.recursiveUpdate {
            # Buzz is this agent's interactive surface, not Hermes's own
            # dashboard/TUI.
            backend.mode = "none";

            # Recommended defaults
            # (hermes-agent.nousresearch.com/docs/user-guide/messaging/buzz)
            # to keep channels clean of tool-call noise and bound inbound
            # latency. require_mention = true is the subordinate default -
            # Leo's own call site overrides it back to false, since he's
            # the primary conversational partner and shouldn't need an
            # @-mention on every message.
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
          } hermesSettings;
        };

        # Hardening gap: the upstream module's own commonServiceConfig
        # (NoNewPrivileges, ProtectSystem=strict, ProtectHome=false,
        # PrivateTmp) is lighter than this fleet's own security posture
        # requires. Layered on top via the HermesSocialDigestPipeline
        # hardening template (nix/module.nix) - NixOS merges serviceConfig
        # attrsets across module files, no upstream patch needed.
        # ProtectHome needs mkForce: the upstream module sets it to `false`
        # at normal priority, so a same-priority `true` would conflict.
        #
        # Deliberately NOT included from that template: StateDirectoryMode.
        # It only has any effect paired with systemd's own `StateDirectory=`
        # option, which this module doesn't use - it manages its state dir
        # itself via systemd.tmpfiles.rules with deliberately group-writable
        # (2770) permissions. Setting StateDirectoryMode alone would be a
        # silent no-op.
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
      };
  };
}
