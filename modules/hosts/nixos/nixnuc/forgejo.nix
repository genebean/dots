# Forgejo server plus its Actions runner, kept together since the runner's
# config directly depends on the server's version and ROOT_URL.
#
# Default server package is forgejo-lts (15.x). Regular (non-LTS) forgejo is
# 16.0.5 on both this pinned nixpkgs and nixpkgs-unstable right now - that
# version match on both channels is what lets the Actions runner below
# (sourced from nixpkgs-unstable, since the services.forgejo-runner module
# doesn't exist on this channel yet) actually pair with this server version.
#
# forgejo-runner is Forgejo's own fork of the Gitea Actions runner - not
# upstream Gitea's act_runner. Confirmed the hard way: the two have genuinely
# different CLIs/registration flows (forgejo-runner takes a --uuid pairing a
# process with a pre-created runner record on the server; act_runner's
# "register --no-interactive" flow has no such concept at all), so
# services.gitea-actions-runner (wraps act_runner) was the wrong module for
# this server regardless of how similar the option shapes looked.
#
# services.forgejo-runner doesn't exist on this pinned nixpkgs channel yet
# (confirmed via nix eval - the option genuinely isn't there) - only on
# nixpkgs-unstable. Importing the module file directly from there, same
# approach as newspaper's genebean.programs.mcp-nixos: pull in just this one
# thing from unstable rather than bumping the whole channel. The module's own
# relative imports (e.g. ../../misc/assertions.nix) resolve correctly against
# nixpkgs-unstable's own tree regardless of how this file itself gets
# imported - Nix path literals are lexically scoped to where they're written,
# not to the importer.
#
# Docker-execution mode (labels referencing "docker://"), not "host" mode -
# jobs run in a fresh container per run, torn down after, isolated from every
# other service on this host. The module auto-detects the podman runtime
# from the label below plus virtualisation.podman.enable (already true here
# - every other nixnuc service is already podman oci-containers) and wires
# up the socket, DOCKER_HOST, and SupplementaryGroups itself.
#
# Jobs get Nix from the official nixos/nix image (pinned to an explicit
# version, not :latest - this is upstream's image, not ours), not a
# custom-built image: Nix itself can pull in whatever else a job needs
# (skopeo for registry pushes, etc.) via `nix run`/`nix shell` at use-time.
#
# This image has no Node.js, which breaks any workflow step using a JS
# GitHub Action (actions/checkout@v4 included - confirmed directly: "node:
# executable file not found in $PATH") since this runner doesn't inject a
# node runtime into the job container the way GitHub's hosted runners do.
# Fix lives in each workflow, not here: a first step does
# `nix profile install nixpkgs#nodejs` (confirmed directly against this
# exact image - lands on /root/.nix-profile/bin, already on this image's
# PATH) before any step that needs a JS action. All steps in a job share
# the same container, so that's enough for the rest of the job too.
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/continuous-integration/forgejo-runner.nix"
  ];

  services = {
    forgejo = {
      enable = true;
      package = pkgs.forgejo;
      database.type = "postgres";
      lfs.enable = true;
      settings = {
        # Add support for actions, based on act: https://github.com/nektos/act
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };
        DEFAULT.APP_NAME = "Beantown's Code";
        repository = {
          DEFAULT_PUSH_CREATE_PRIVATE = true;
          ENABLE_PUSH_CREATE_ORG = true;
          ENABLE_PUSH_CREATE_USER = true;
        };
        server = {
          DOMAIN = "git.home.technicalissues.us";
          HTTP_PORT = config.genebean.ports.forgejo.port;
          LANDING_PAGE = "explore";
          ROOT_URL = "https://git.home.technicalissues.us/";
        };
        service.DISABLE_REGISTRATION = true;
        session.COOKIE_SECURE = true;
      };
      stateDir = "/orico/forgejo";
    };

    forgejo-runner = {
      package =
        (import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; }).forgejo-runner;

      instances.nixnuc01 = {
        enable = true;
        settings = {
          server.connections.home = {
            url = config.services.forgejo.settings.server.ROOT_URL;
            # Pre-assigned when the runner was registered via Forgejo's own
            # admin UI (Site Administration -> Actions -> Runners -> Create
            # new runner) - this pairs this process with that specific
            # runner record. Not a secret on its own (the token is the
            # actual credential), but changing it requires a fresh
            # registration either way.
            uuid = "eec3ff2b-d61f-4541-9cee-75e2370616bf";
          };
          runner.labels = [
            "nix:docker://nixos/nix:2.35.2"
          ];
        };
        secrets.server.connections.home.token_url = config.sops.secrets.forgejo_runner_nixnuc01_token.path;
      };
    };

    restic.backups.daily.paths = [
      config.services.forgejo.stateDir
    ];
  };

  sops.secrets.forgejo_runner_nixnuc01_token = {
    restartUnits = [ "forgejo-runner-nixnuc01.service" ];
  };
}
