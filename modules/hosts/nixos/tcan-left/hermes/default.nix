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
  ];

  sops.secrets = {
    hermes_leo_buzz_identity = {
      sopsFile = ../../../../shared/secrets.yaml;
    };
    hermes_cj_buzz_identity = {
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
