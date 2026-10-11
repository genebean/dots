# newspaper: static Zola site. The image is built and pushed entirely by
# the newspaper repo's own Forgejo Actions CI
# (git.home.technicalissues.us/genebean/newspaper:latest) - this file only
# declares the running container plus the deploy-trigger webhook CI calls as
# its last step. No Nix-built image, no repo content, lives here.
{ config, pkgs, ... }:
let
  serviceName = config.virtualisation.oci-containers.containers.newspaper.serviceName;

  deployScript = pkgs.writeShellScript "newspaper-webhook-deploy" ''
    ${pkgs.podman}/bin/podman pull git.home.technicalissues.us/genebean/newspaper:latest
    systemctl restart ${serviceName}.service
  '';
in
{
  virtualisation.oci-containers.containers.newspaper = {
    autoStart = true;
    image = "git.home.technicalissues.us/genebean/newspaper:latest";
    # :latest is a moving tag - without this, "pull missing" (the default)
    # treats any locally-cached image with that name:tag as already correct
    # and never re-checks the registry, so a plain `systemctl restart`
    # (outside the webhook/podman-auto-update paths, which both pull
    # explicitly first) would just respawn the stale image.
    pull = "always";
    # Podman auto-update safety net (podman-auto-update.timer, enabled
    # below) - a slower backstop in case the webhook call from CI is ever
    # missed. The webhook is still the fast path for a normal deploy.
    labels."io.containers.autoupdate" = "registry";
    login = {
      registry = "https://git.home.technicalissues.us";
      username = "genebean";
      passwordFile = config.sops.secrets.forgejo_package_read_token.path;
    };
    ports = [
      "127.0.0.1:${toString config.genebean.ports.newspaper.port}:8080"
    ];
  };

  # Shipped by the podman package but not enabled by default (confirmed via
  # `systemctl is-enabled podman-auto-update.timer` on this host: "linked",
  # not active) - this is the first container on nixnuc to opt in via the
  # autoupdate label above.
  systemd.timers."podman-auto-update".wantedBy = [ "timers.target" ];

  # Runs as root (not the module's default unprivileged "webhook" user) -
  # its one job is podman pull + systemctl restart on the unit above, both
  # of which need root's own podman socket/auth.json and systemd access.
  services.webhook = {
    enable = true;
    ip = "127.0.0.1";
    port = config.genebean.ports.newspaper-webhook.port;
    user = "root";
    group = "root";
    # Satisfies the module's "at least one hook" assertion with something
    # genuinely useful (a liveness probe) - the real, secret-gated deploy
    # hook is injected separately below via extraArgs, because its
    # trigger-rule needs a sops-decrypted token that must never land in the
    # Nix store the way services.webhook.hooks would put it.
    hooks.ping = {
      execute-command = "${pkgs.coreutils}/bin/true";
      response-message = "newspaper webhook is reachable";
    };
    extraArgs = [
      "-hooks"
      config.sops.templates."newspaper-webhook-hooks.json".path
    ];
  };

  sops.secrets = {
    # PAT with package:read scope, created via the Forgejo admin UI under
    # the genebean account - used to pull the (private) image. Lives in
    # the shared secrets file, not nixnuc's own - named for what it is
    # (a Forgejo package-registry token), not what uses it.
    forgejo_package_read_token = {
      sopsFile = ../../../shared/secrets.yaml;
      restartUnits = [ "${serviceName}.service" ];
    };
    # Bearer token CI sends in the X-Deploy-Token header as the last step
    # of the publish-container workflow. Only ever touches disk via the
    # sops.templates render below, never the Nix store.
    forgejo_nixnuc_deploy_webhook_token = {
      sopsFile = ../../../shared/secrets.yaml;
    };
    # htpasswd-format file content (not a plain password) gating the site
    # itself - same pattern as the existing nginx_basic_auth secret for
    # monitoring, but a separate credential since the intended audience is
    # different (newspaper readers, not fleet monitoring access).
    newspaper_basic_auth = {
      sopsFile = ../../../shared/secrets.yaml;
      owner = "nginx";
      restartUnits = [ "nginx.service" ];
    };
  };

  sops.templates."newspaper-webhook-hooks.json" = {
    content = builtins.toJSON [
      {
        id = "newspaper-deploy";
        execute-command = "${deployScript}";
        trigger-rule = {
          match = {
            type = "value";
            value = config.sops.placeholder.forgejo_nixnuc_deploy_webhook_token;
            parameter = {
              source = "header";
              name = "X-Deploy-Token";
            };
          };
        };
      }
    ];
    restartUnits = [ "webhook.service" ];
  };
}
