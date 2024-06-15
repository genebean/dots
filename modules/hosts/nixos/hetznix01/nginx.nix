{ ... }: let 
  http_port = 80;
  https_port = 443;
in {
  imports = [
    ../../../system/common/linux/lets-encrypt.nix
  ];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000 always;";
      }
      add_header Strict-Transport-Security $hsts_header;
    '';
    virtualHosts = {
      "hetznix01.technicalissues.us" = {
        default = true;
        listen = [
          { port = http_port; addr = "0.0.0.0"; }
          { port = https_port; addr = "0.0.0.0"; ssl = true; }
        ];
        enableACME = true;
        acmeRoot = null;
        addSSL = true;
        forceSSL = false;
        locations."/" = {
          return = "200 '<h1>Hello world ;)</h1>'";
          extraConfig = ''
            add_header Content-Type text/html;
          '';
        };
      };
      "utk.technicalissues.us" = {
        listen = [{ port = https_port; addr = "0.0.0.0"; ssl = true; }];
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/".proxyWebsockets = true;
        locations."/".proxyPass = "http://127.0.0.1:3001";
      };
    }; # end virtualHosts
  }; # end nginx
}
