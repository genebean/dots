{ config, ... }: let 
  domain = "technicalissues.us";
  http_port = 80;
  https_port = 443;
in {

  services.nginx = {
    enable = true;
    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000;";
      }
      add_header Strict-Transport-Security $hsts_header;
    '';
    defaultListen = [
      { port = http_port; addr = "0.0.0.0"; }
      { port = http_port; addr = "[::]"; }

      { port = https_port; addr = "0.0.0.0"; ssl = true; }
      { port = https_port; addr = "[::]"; ssl = true; }
    ];
    virtualHosts = {
      "hetznix01.${domain}" = {
        serverAliases = [
          "technicalissues.us"
          "alt.technicalissues.us"
          "mail.alt.technicalissues.us"
        ];
        default = true;
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations = {
          "/" = {
            return = "301 https://beanbag.technicalissues.us";
          };
          "/.well-known/lnurlp/genebean" = {
            return = ''
              200 '{"status":"OK","tag":"payRequest","commentAllowed":255,"callback":"https://getalby.com/lnurlp/genebean/callback","metadata":"[[\\"text/identifier\\",\\"genebean@getalby.com\\"],[\\"text/plain\\",\\"Sats for GeneBean\\"]]","minSendable":1000,"maxSendable":150000000,"payerData":{"name":{"mandatory":false},"email":{"mandatory":false},"pubkey":{"mandatory":false}},"nostrPubkey":"79f00d3f5a19ec806189fcab03c1be4ff81d18ee4f653c88fac41fe03570f432","allowsNostr":true}'
            '';
            extraConfig = ''
              default_type application/json;
              source_charset utf-8;
              charset utf-8;
              add_header Access-Control-Allow-Origin *;
            '';
          };
          "/.well-known/matrix/client" = {
            return = ''
              200 '{"m.homeserver": {"base_url": "https://matrix.technicalissues.us"}}'
            '';
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
            '';
          };
          "/.well-known/matrix/server" = {
            return = ''
              200 '{"m.server": "matrix.technicalissues.us"}'
            '';
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
            '';
          };
        };
      };
      "albyhub.${domain}" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
       # basicAuthFile = config.sops.secrets.owntracks_basic_auth.path;
        # Albyhub container
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
      };
      "matrix.${domain}" = {
        listen = [
          { port = http_port; addr = "0.0.0.0"; }
          { port = http_port; addr = "[::]"; }

          { port = https_port; addr = "0.0.0.0"; ssl = true; }
          { port = https_port; addr = "[::]"; ssl = true; }

          { port = 8448; addr = "0.0.0.0"; ssl = true; }
          { port = 8448; addr = "[::]"; ssl = true; }
        ];
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        extraConfig = ''
          client_max_body_size 0;
        '';
        locations = {
          "/" = {
            return = "200 '<h1>Hi.</h1>'";
            extraConfig = ''
              add_header Content-Type text/html;
            '';
          };
          # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
          # *must not* be used here.
          "/_matrix".proxyPass = "http://[::1]:8008";
          # Forward requests for e.g. SSO and password-resets.
          "/_synapse/client".proxyPass = "http://[::1]:8008";
        };
      };
      "ot.${domain}" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        basicAuthFile = config.sops.secrets.owntracks_basic_auth.path;
        # OwnTracks Frontend container
        locations."/".proxyPass = "http://127.0.0.1:8082";
      };
      "recorder.${domain}" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        basicAuthFile = config.sops.secrets.owntracks_basic_auth.path;
        locations = {
          # OwnTracks Recorder
          "/" = {
            proxyPass = "http://127.0.0.1:8083";
          };
          "/pub" = { # Client apps need to point to this path
            extraConfig = "proxy_set_header X-Limit-U $remote_user;";
            proxyPass = "http://127.0.0.1:8083/pub";
          };
          "/static/" = {
            proxyPass = "http://127.0.0.1:8083/static/";
          };
          "/utils/" = {
            proxyPass = "http://127.0.0.1:8083/utils/";
          };
          "/view/" = {
            extraConfig = "proxy_buffering off;";
            proxyPass = "http://127.0.0.1:8083/view/";
          };
          "/ws" = {
            extraConfig = "rewrite ^/(.*) /$1 break;";
            proxyPass = "http://127.0.0.1:8083";
          };
        };
      };
      "stats.${domain}" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:8001";
      };
      "utk.${domain}" = {
        serverAliases = [
          "pi-status.${domain}"
          "status.${domain}"
        ];
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/".proxyWebsockets = true;
        locations."/".proxyPass = "http://127.0.0.1:3001";
      };
    }; # end virtualHosts
  }; # end nginx
}
