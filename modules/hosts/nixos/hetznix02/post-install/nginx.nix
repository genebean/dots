
{ config, pkgs, ... }: let
  domain = "genebean.me";
  http_port = 80;
  https_port = 443;
in {
  environment.etc.nginx-littlelinks = {
    # Info generated via
    # nurl https://github.com/genebean/littlelink genebean-sometag
    source = pkgs.fetchFromGitHub {
      owner = "genebean";
      repo = "littlelink";
      rev = "genebean-1.0.1";
      hash = "sha256-r7cvcKdlivQ2MA1UhypwdJrg7CREzTZE5fiNA9AWY/0=";
    };
  };

  security.acme.certs."${domain}" = {
    email = "lets-encrypt@technicalissues.us";
    inheritDefaults = false;
    listenHTTP = ":80";
    # uncomment below for testing
    # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  };

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
    virtualHosts = {
      "${domain}" = {
        serverAliases = [
          "www.${domain}"
        ];
        default = true;
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        locations = {
          "/" = {
            root = "/etc/nginx-littlelinks";
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
          "/.well-known/nostr.json" = {
            return = ''
              200 '{"names": {"genebean": "dba168fc95fdbd94b40096f4a6db1a296c0e85c4231bfc9226fca5b7fcc3e5ca"}}'
            '';
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin *;
            '';
          };
          "/api/event" = {
            return = "301 https://stats.technicalissues.us/api/event";
          };
          "/github" = {
            return = "301 https://github.com/genebean";
          };
          "/js/script.outbound-links.js" = {
            return = "301 https://stats.technicalissues.us/js/script.outbound-links.js";
          };
          "/mastodon" = {
            return = "302 https://fosstodon.org/@genebean";
          };
          "/nostr" = {
            return = "302 https://primal.net/p/npub1mwsk3ly4lk7efdqqjm62dkc699kqapwyyvdley3xljjm0lxruh9qzvu46p";
          };
        };
      }; # end bare domain
    }; # end virtualHosts
  }; # end nginx
}
