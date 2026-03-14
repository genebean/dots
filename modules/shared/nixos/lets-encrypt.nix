{ config, username, ... }: {

  ##########################################################################
  #                                                                        #
  #  This module sets up Let's Encrypt certs via a DNS challenge to Gandi  #
  #                                                                        #
  ##########################################################################

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "lets-encrypt@technicalissues.us";
      credentialFiles = { "GANDIV5_PERSONAL_ACCESS_TOKEN_FILE" = "${config.sops.secrets.gandi_dns_pat.path}"; };
      dnsProvider = "gandiv5";
      dnsResolver = "ns1.gandi.net";
      # uncomment below for testing
      #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    secrets.gandi_dns_pat.sopsFile = ../secrets.yaml;
  };
}
