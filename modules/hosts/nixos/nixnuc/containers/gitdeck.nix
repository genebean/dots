# Gitdeck is an upstream-built Node app, with no published container image.
# Build its Dockerfile from a pinned GitHub archive, as Scotty does, and run
# the image with nixnuc's existing Podman OCI container backend.
{
  config,
  pkgs,
  ...
}:
let
  version = "v1.0.10";
  revision = "f77bde35427f7de4ae9ecd3e6ae1b0ca0ca7e552";
  archive = pkgs.fetchurl {
    url = "https://github.com/debba/gitdeck/archive/${revision}.tar.gz";
    hash = "sha256-LLbijIsj9VaCWzXNxvTXLdfn5nJOeQMq1NpID9xqIek=";
  };
  source =
    pkgs.runCommandNoCC "gitdeck-${version}-source"
      {
        nativeBuildInputs = [ pkgs.gzip ];
      }
      ''
        mkdir -p "$out"
        ${pkgs.gnutar}/bin/tar -xzf ${archive} --strip-components=1 -C "$out"
      '';
  image = "gitdeck:${version}-${builtins.substring 0 7 revision}";
  container = "gitdeck";
  service = config.virtualisation.oci-containers.containers.${container}.serviceName;
in
{
  systemd = {
    tmpfiles.rules = [
      "d /var/lib/gitdeck 0700 root root -"
      # The upstream entrypoint chowns this directory to its `node` user
      # before dropping privileges. It must be writable and persistent.
      "d /var/lib/gitdeck/data 0700 root root -"
      "d /etc/gitdeck 0755 root root -"
    ];

    services = {
      gitdeck-build-image = {
        description = "Build Gitdeck ${version} container image";
        wantedBy = [ "multi-user.target" ];
        before = [ "${service}.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          if ! ${pkgs.podman}/bin/podman image exists ${image}; then
            ${pkgs.podman}/bin/podman build -t ${image} ${source}
          fi
        '';
      };

      ${service} = {
        after = [ "gitdeck-build-image.service" ];
        requires = [ "gitdeck-build-image.service" ];
        # GitHub's OAuth App client ID is created by the account owner.
        # Skipping startup until it is configured avoids a broken login UI
        # and lets the rest of the NixOS generation deploy normally.
        unitConfig.ConditionPathExists = "/etc/gitdeck/oauth.env";
        serviceConfig.EnvironmentFile = "/etc/gitdeck/oauth.env";
      };
    };
  };

  virtualisation.oci-containers.containers.${container} = {
    inherit image;
    autoStart = true;
    # The host only publishes this on its LAN IP. Tailscale clients already
    # have a route to this subnet; there is no public nginx virtual host.
    ports = [
      "192.168.20.190:${toString config.genebean.ports.gitdeck.port}:8765"
    ];
    # Podman copies the ID from the systemd EnvironmentFile into the image.
    # The client ID is public; Gitdeck stores the OAuth access token in data.
    extraOptions = [
      "--env=GITHUB_CLIENT_ID"
      "--env=GITHUB_OAUTH_SCOPES"
      "--security-opt=no-new-privileges"
    ];
    volumes = [
      "/var/lib/gitdeck/data:/home/node/.gitdeck:rw"
    ];
  };
}
