# Gitdeck uses the published GHCR image and nixnuc's Podman OCI backend.
{
  config,
  lib,
  ...
}:
let
  container = "gitdeck";
  clientId = config.genebean.gitdeck.githubClientId;
in
{
  options.genebean.gitdeck.githubClientId = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Public GitHub OAuth App Client ID for Gitdeck. Set this in Nix
      configuration after enabling Device Flow on the OAuth App. Gitdeck
      is disabled until a non-empty Client ID is provided.
    '';
  };

  config = {
    # Keep the backup path present even before the Client ID is configured.
    systemd.tmpfiles.rules = [
      "d /var/lib/gitdeck 0700 root root -"
      # The upstream entrypoint chowns this directory to its `node` user
      # before dropping privileges. It must be writable and persistent.
      "d /var/lib/gitdeck/data 0700 root root -"
    ];

    virtualisation.oci-containers.containers = lib.mkIf (clientId != null && clientId != "") {
      ${container} = {
        # Renovate's OCI regex manager tracks this literal image tag.
        image = "ghcr.io/debba/gitdeck:v1.0.10";
        autoStart = true;
        # The Client ID is public; Gitdeck keeps the OAuth access token in its
        # data volume, not in the Nix store or a manually installed env file.
        environment.GITHUB_CLIENT_ID = clientId;
        # Publish on all host interfaces, like the other OCI containers.
        ports = [
          "${toString config.genebean.ports.gitdeck.port}:8765"
        ];
        extraOptions = [ "--security-opt=no-new-privileges" ];
        volumes = [
          "/var/lib/gitdeck/data:/home/node/.gitdeck:rw"
        ];
      };
    };
  };
}
