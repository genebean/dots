{ config, pkgs, ... }: let
  #
in {
  services.matrix-synapse = {
    enable = true;
    configureRedisLocally = true;
    settings = {
      public_baseurl = "https://matrix.technicalissues.us";
      listeners = [
        {
          port = 8008;
          tls = false;
          type = "http";
          x_forwarded = true;
          bind_addresses = [
            "::1"
            "127.0.0.1"
          ];
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = false;
            }
          ];
        }
      ];
      database = {
        name = "psycopg2";
        args = {
          user = "synapse_user";
          database = "synapse";
        };
      };
      url_preview_enabled = true;
      enable_registration = false;
      registration_shared_secret = config.sops.secrets.matrix-registration_shared_secret;
      macaroon_secret_key = config.sops.secrets.matrix-macaroon_secret_key;
      trusted_key_servers = [{ server_name = "matrix.org"; }];

    };

  };
}
