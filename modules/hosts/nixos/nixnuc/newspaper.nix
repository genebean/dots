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
  services = {
    # Gates the newspaper vhost against PocketID for human readers,
    # restricted to the "beantown_subscribers" PocketID group. Hermes
    # agents (which can't do an interactive OIDC login) use the
    # basicAuthFile on the "/" location in default.nix instead, combined
    # via `satisfy any;` there.
    oauth2-proxy = {
      enable = true;
      clientID = "195c68b6-1600-4620-ad89-37beee72b5e0"; # PocketID client "The Paper"
      clientSecretFile = config.sops.secrets.newspaper_oauth2_client_secret.path;
      cookie.secretFile = config.sops.secrets.newspaper_oauth2_cookie_secret.path;
      extraConfig = {
        "code-challenge-method" = "S256"; # For PKCE
        # Without this, every login's post-auth redirect back to the site's
        # own URL gets rejected ("domain / port not in whitelist") and falls
        # back to a generic default instead of returning the user to where
        # they started. Confirmed live in oauth2-proxy's logs.
        "whitelist-domain" = "newspaper.home.technicalissues.us";
      };
      email.domains = [ "*" ];
      httpAddress = "http://127.0.0.1:${toString config.genebean.ports.newspaper-oauth2-proxy.port}";
      nginx = {
        domain = "newspaper.home.technicalissues.us";
        virtualHosts."newspaper.home.technicalissues.us" = {
          allowed_groups = [ "beantown_subscribers" ];
        };
      };
      oidcIssuerUrl = config.services.pocket-id.settings.APP_URL;
      provider = "oidc";
      redirectURL = "https://newspaper.home.technicalissues.us/oauth2/callback";
      reverseProxy = true;
      scope = "openid email profile groups";
      setXauthrequest = true;
      trustedProxyIP = [
        "127.0.0.1"
      ];
    };

    # Runs as root (not the module's default unprivileged "webhook" user) -
    # its one job is podman pull + systemctl restart on the unit above, both
    # of which need root's own podman socket/auth.json and systemd access.
    webhook = {
      enable = true;
      ip = "127.0.0.1";
      port = config.genebean.ports.newspaper-webhook.port;
      user = "root";
      group = "root";
      # Satisfies the module's "at least one hook" assertion with something
      # genuinely useful (a liveness probe) - the real, secret-gated deploy
      # hook is injected separately below via extraArgs, because its
      # trigger-rule needs a sops-decrypted token that must never land in
      # the Nix store the way services.webhook.hooks would put it.
      hooks.ping = {
        execute-command = "${pkgs.coreutils}/bin/true";
        response-message = "newspaper webhook is reachable";
      };
      extraArgs = [
        "-hooks"
        config.sops.templates."newspaper-webhook-hooks.json".path
      ];
    };

  };

  sops = {
    secrets = {
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
      # htpasswd-format file content (not a plain password). Originally the
      # stopgap for human access before PocketID landed; now the permanent
      # credential for Hermes agents (which can't do an interactive OIDC
      # login) via the nginx `satisfy any;` below - humans go through
      # PocketID instead.
      newspaper_basic_auth = {
        sopsFile = ../../../shared/secrets.yaml;
        owner = "nginx";
        restartUnits = [ "nginx.service" ];
      };
      # OIDC client secret for "The Paper" client created in PocketID's
      # admin UI (Clients -> New Client).
      newspaper_oauth2_client_secret = {
        sopsFile = ../../../shared/secrets.yaml;
        restartUnits = [ "oauth2-proxy.service" ];
      };
      # oauth2-proxy's own session-cookie signing key - not tied to PocketID,
      # just needs to be a random value (e.g. `openssl rand -base64 32`).
      newspaper_oauth2_cookie_secret = {
        sopsFile = ../../../shared/secrets.yaml;
        restartUnits = [ "oauth2-proxy.service" ];
      };
    };

    templates."newspaper-webhook-hooks.json" = {
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
  };

  # Shipped by the podman package but not enabled by default (confirmed via
  # `systemctl is-enabled podman-auto-update.timer` on this host: "linked",
  # not active) - this is the first container on nixnuc to opt in via the
  # autoupdate label above.
  systemd.timers."podman-auto-update".wantedBy = [ "timers.target" ];

  # pull = "always" means every activation re-pulls from Forgejo's own
  # registry (git.home.technicalissues.us) - without this ordering, a
  # generation that restarts both forgejo.service and podman-newspaper.service
  # together races newspaper's pull against Forgejo still coming back up,
  # intermittently failing with "502 Bad Gateway" pinging the registry.
  # Confirmed live 2026-10-21: this raced and failed deploy-rs's activation
  # wait, triggering an automatic rollback.
  systemd.services.podman-newspaper = {
    after = [ "forgejo.service" ];
    wants = [ "forgejo.service" ];
  };

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
}
