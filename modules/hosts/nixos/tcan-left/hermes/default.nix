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

  sops.secrets = {
    hermes_leo_buzz_identity = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_cj_buzz_identity = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_sam_buzz_identity = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_sam_github_app_key = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    # Separate App, separate private key - scoped only to genebean/agent-ideas
    # (Issues: read+write, Contents: read), installed directly on the
    # genebean account since that's the only way to reach a repo mylittletechbot
    # is merely a collaborator on, not owner of. Deliberately not the same
    # App as hermes_sam_github_app_key above (that one stays on mylittletechbot,
    # all-repos-it-owns, for the public product-repo fork/PR workflow) -
    # keeping them separate means this narrow, genebean-installed credential
    # can never be used for anything broader than this one repo.
    hermes_sam_agent_ideas_app_key = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_charlie_buzz_identity = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_charlie_forgejo_token = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_danny_buzz_identity = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    # Same literal bearer-token value as nixnuc's social-reader-mcp (single
    # shared-secret auth, not a per-consumer token) - hermes-agent-fleet-plan
    # issue 39.
    hermes_danny_mcp_token = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
  };
}
