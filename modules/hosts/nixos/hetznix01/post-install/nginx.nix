{ config, ... }:
let
  domain = "technicalissues.us";
  private_btc = "umbrel.${config.private-flake.tailnetDomain}";
in
{

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
    streamConfig = ''
      server {
        # https://docs.emqx.com/en/emqx/latest/deploy/cluster/lb-nginx.html
        listen ${toString config.dots.ports.mqtt-tls.port} ssl;
        ssl_session_timeout 10m;
        ssl_certificate ${config.security.acme.certs."mqtt.${domain}".directory}/fullchain.pem;
        ssl_certificate_key ${config.security.acme.certs."mqtt.${domain}".directory}/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
        proxy_pass 127.0.0.0:${toString config.dots.ports.mqtt.port};
        proxy_protocol on;
        proxy_connect_timeout 10s;
        # Default keep-alive time is 10 minutes
        proxy_timeout 1800s;
        proxy_buffer_size 3M;
        tcp_nodelay on;
      }

      server {
        listen 0.0.0.0:${toString config.dots.ports.bitcoin-core.port};
        listen 0.0.0.0:${toString config.dots.ports.bitcoin-knots.port};
        listen [::]:${toString config.dots.ports.bitcoin-core.port};
        listen [::]:${toString config.dots.ports.bitcoin-knots.port};
        proxy_pass ${private_btc}:${toString config.dots.ports.bitcoin-core.port};
      }

      server {
        listen 0.0.0.0:${toString config.dots.ports.lnd.port};
        listen [::]:${toString config.dots.ports.lnd.port};
        proxy_pass ${private_btc}:${toString config.dots.ports.lnd.port};
      }
    '';
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
              200 '{"status":"OK","tag":"payRequest","commentAllowed":255,"callback":"https://getalby.com/lnurlp/genebean/callback","metadata":"[[\\"text/identifier\\",\\"genebean@getalby.com\\"],[\\"text/plain\\",\\"Sats for GeneBean\\"]]","minSendable":1000,"maxSendable":10000000000,"payerData":{"name":{"mandatory":false},"email":{"mandatory":false},"pubkey":{"mandatory":false}},"nostrPubkey":"79f00d3f5a19ec806189fcab03c1be4ff81d18ee4f653c88fac41fe03570f432","allowsNostr":true}'
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
          "/.well-known/nostr.json" = {
            return = ''
              200 '{"names": {"genebean": "dba168fc95fdbd94b40096f4a6db1a296c0e85c4231bfc9226fca5b7fcc3e5ca"}}'
            '';
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
            '';
          };
        };
      };
      "cloud.pack1828.org" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
      };
      "collabora.pack1828.org" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
          proxyWebsockets = true; # collabora uses websockets
        };
      };
      "location.${domain}" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        # Other settings come from services.dawarich.configureNginx
        # The client_max_body_size setting is need to allow for large GeoJSON files
        # such as those exported from a containerized version of Dawarich.
        extraConfig = ''
          client_max_body_size 200m;
        '';
      };
      "matrix.${domain}" = {
        listen = [
          {
            inherit (config.dots.ports.http) port;
            addr = "0.0.0.0";
          }
          {
            inherit (config.dots.ports.http) port;
            addr = "[::]";
          }

          {
            inherit (config.dots.ports.https) port;
            addr = "0.0.0.0";
            ssl = true;
          }
          {
            inherit (config.dots.ports.https) port;
            addr = "[::]";
            ssl = true;
          }

          {
            inherit (config.dots.ports.matrix-federation) port;
            addr = "0.0.0.0";
            ssl = true;
          }
          {
            inherit (config.dots.ports.matrix-federation) port;
            addr = "[::]";
            ssl = true;
          }
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
          "/_matrix".proxyPass = "http://[::1]:${toString config.dots.ports.matrix-synapse.port}";
          # Forward requests for e.g. SSO and password-resets.
          "/_synapse/client".proxyPass = "http://[::1]:${toString config.dots.ports.matrix-synapse.port}";
        };
      };
      "mqtt.${domain}" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/".return = "301 https://beanbag.technicalissues.us";
      };
      "pack1828.org" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/" = {
          return = "307 https://cloud.pack1828.org";
        };
      };
      "stats.${domain}" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.dots.ports.plausible.port}";
        locations."/".proxyWebsockets = true;
        extraConfig = ''
          access_log /var/log/nginx/stats.${domain}.log;
        '';
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
        locations."/".proxyPass = "http://127.0.0.1:${toString config.dots.ports.uptime-kuma.port}";
      };
    }; # end virtualHosts
  }; # end nginx
}
