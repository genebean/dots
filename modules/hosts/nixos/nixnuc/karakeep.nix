{
  config,
  lib,
  pkgs,
  ...
}:
let
  home_domain = "home.technicalissues.us";
in
{
  services.karakeep = {
    enable = true;
    environmentFile = config.sops.secrets.karakeep_env.path;
    extraEnvironment = {
      PORT = toString config.genebean.ports.karakeep.port;
      NEXTAUTH_URL = "https://karakeep.${home_domain}";
      # Left open deliberately: DISABLE_PASSWORD_AUTH below means the only
      # way in is still Pocket ID OIDC, so this just lets other accounts in
      # that same Pocket ID instance self-register if they want in - no
      # open signup surface for anyone outside it.
      DISABLE_SIGNUPS = "false";
      DISABLE_PASSWORD_AUTH = "true";
      DISABLE_NEW_RELEASE_CHECK = "true";
      OAUTH_WELLKNOWN_URL = "https://id.${home_domain}/.well-known/openid-configuration";
      OAUTH_PROVIDER_NAME = "Pocket ID";
      OAUTH_AUTO_REDIRECT = "true";
    };
  };

  services.restic.backups.daily.paths = [ "/var/lib/karakeep" ];

  # karakeep-web does its own OIDC discovery against PocketID at startup
  # (same as oauth2-proxy in newspaper.nix) and exits non-zero if it gets
  # anything but a 200. Same race as that module's fix: a deploy that
  # restarts nginx and pocket-id in the same batch 502s this for the few
  # seconds pocket-id takes to come back up, and the stock unit can burn
  # through its restart-start-limit before pocket-id recovers, which fails
  # switch-to-configuration and rolls the whole deploy back. Ordering alone
  # isn't enough since "Started" precedes "listening" - the start itself
  # has to wait until discovery actually succeeds.
  systemd.services.karakeep-web.serviceConfig = {
    ExecStartPre = lib.concatStringsSep " " [
      "${pkgs.curl}/bin/curl"
      "--silent --show-error --fail --output /dev/null"
      "--max-time 5 --retry 60 --retry-delay 1 --retry-max-time 60 --retry-all-errors"
      "https://id.${home_domain}/.well-known/openid-configuration"
    ];
    # Backstop for a crash after discovery succeeded: back off instead of
    # tripping the start limit and staying down until someone notices.
    RestartSec = "10s";
  };
}
