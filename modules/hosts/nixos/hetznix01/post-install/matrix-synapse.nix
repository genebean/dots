{ config, pkgs, ... }: let
  #
in {
  services.matrix-synapse = {
    enable = true;
    configureRedisLocally = true;
    enableRegistrationScript = true;
    extraConfigFiles = [
      config.sops.secrets.matrix_secrets_yaml.path
    ];
    settings = {
      public_baseurl = "https://matrix-test.technicalissues.us";
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
      trusted_key_servers = [{ server_name = "matrix.org"; }];

    };

  };
}
