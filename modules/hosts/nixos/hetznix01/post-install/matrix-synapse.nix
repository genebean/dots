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
      server_name = "technicalissues.us";
      public_baseurl = "https://matrix.technicalissues.us";
      signing_key_path = config.sops.secrets.matrix_homeserver_signing_key.path;
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
      url_preview_enabled = true;
      enable_registration = false;
      trusted_key_servers = [{ server_name = "matrix.org"; }];
    };

  };
}
