{ config, ... }:
let
  home_domain = "home.technicalissues.us";
in
{
  services.karakeep = {
    enable = true;
    environmentFile = config.sops.secrets.karakeep_env.path;
    extraEnvironment = {
      PORT = toString config.dots.ports.karakeep.port;
      NEXTAUTH_URL = "https://karakeep.${home_domain}";
      DISABLE_SIGNUPS = "true";
      DISABLE_PASSWORD_AUTH = "true";
      DISABLE_NEW_RELEASE_CHECK = "true";
      OAUTH_WELLKNOWN_URL = "https://id.${home_domain}/.well-known/openid-configuration";
      OAUTH_PROVIDER_NAME = "Pocket ID";
      OAUTH_AUTO_REDIRECT = "true";
    };
  };

  services.restic.backups.daily.paths = [ "/var/lib/karakeep" ];
}
