# Hermes agent fleet on tcan-left: one systemd-nspawn container per agent
# (see ./container-builder.nix for why), each running services.hermes-agent
# as that container's only profile.
#
# Secrets are decrypted here, on the host, from the fleet-wide
# modules/shared/secrets.yaml (not a tcan-left-local file - these
# identities are portable across whichever host/container ends up running
# them, not pinned to this one). Each agent's own default.nix (a sibling
# import, so it sees the same `config` fixed point) bind-mounts the
# specific decrypted file(s) it needs via config.sops.secrets.<name>.path
# into its own container; the containers themselves never import sops-nix
# or hold an age identity.
{
  imports = [
    ./leo
    ./charlie
    ./danny
    ./cj
    ./sam
  ];

  # restartUnits on every secret below: a container's secretBindMounts are
  # established once, at container start - if only a secret's content
  # changes (no unit config change), sops-nix swaps the host's /run/secrets
  # symlink target but nothing restarts the container, so its bind-mounted
  # copy goes stale (confirmed directly: hermes-cj's forgejo token kept
  # resolving to a prior value through two content-only redeploys, until
  # `systemctl restart container@cj` picked up the new target). Listing the
  # owning container's unit here makes sops-nix restart it automatically on
  # every secret change, the same way `restartTriggers` would.
  sops.secrets = {
    hermes_charlie_buzz_identity = {
      restartUnits = [ "container@charlie.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_charlie_forgejo_token = {
      restartUnits = [ "container@charlie.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_cj_buzz_identity = {
      restartUnits = [ "container@cj.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    # Same shape as hermes_danny_forgejo_token below, for C.J.'s
    # "Official statement" and "Official briefing" record types
    # (articles/official-statement/, articles/official-briefing/) - see
    # her AGENTS.md.
    hermes_cj_forgejo_token = {
      restartUnits = [ "container@cj.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_danny_buzz_identity = {
      restartUnits = [ "container@danny.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    # Danny's own write-collaborator Forgejo token on genebean/newspaper,
    # scoped to his "Independent reporting" record type only
    # (articles/independent-reporting/) - a social/review-enforced
    # boundary, not a technical one yet (see his AGENTS.md). main is
    # branch-protected: no direct push, one required approval, approval
    # restricted to genebean - so nothing he writes reaches the canonical
    # record without the user reviewing it first.
    hermes_danny_forgejo_token = {
      restartUnits = [ "container@danny.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    # Same literal bearer-token value as nixnuc's social-reader-mcp (single
    # shared-secret auth, not a per-consumer token) - hermes-agent-fleet-plan
    # issue 39.
    hermes_danny_mcp_token = {
      restartUnits = [ "container@danny.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_leo_buzz_identity = {
      restartUnits = [ "container@leo.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    # Separate App, separate private key - scoped only to genebean/agent-ideas
    # (Issues: read+write, Contents: read), installed directly on the
    # genebean account since that's the only way to reach a repo mylittletechbot
    # is merely a collaborator on, not owner of. Deliberately not the same
    # App as hermes_sam_github_app_key below (that one stays on mylittletechbot,
    # all-repos-it-owns, for the public product-repo fork/PR workflow) -
    # keeping them separate means this narrow, genebean-installed credential
    # can never be used for anything broader than this one repo.
    hermes_sam_agent_ideas_app_key = {
      restartUnits = [ "container@sam.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_sam_buzz_identity = {
      restartUnits = [ "container@sam.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_sam_github_app_key = {
      restartUnits = [ "container@sam.service" ];
      sopsFile = ../../../../shared/secrets.yaml;
    };
  };
}
