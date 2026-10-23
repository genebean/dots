{

  ##########################################################################
  #                                                                        #
  #  Generic fail2ban coverage for any host running nginx as a public     #
  #  reverse proxy. Split across two jails because nginx splits its own   #
  #  logging the same way (confirmed against the nixpkgs nginx module     #
  #  source, nixos/modules/services/web-servers/nginx/default.nix):       #
  #    - error_log defaults to "stderr", captured by journald under the  #
  #      nginx.service unit - that's where failed basic-auth attempts    #
  #      show up, so nginx-http-auth reads the journal.                  #
  #    - access_log has no module-level override and falls back to       #
  #      nginx's own compiled default at /var/log/nginx/access.log (a    #
  #      real file, not journald) - that's where 404 scanner/bot request #
  #      patterns show up, so nginx-botsearch reads that file.           #
  #  Both filters ship bundled with the fail2ban package itself - no      #
  #  filter file symlinking needed (unlike wp-fail2ban in                #
  #  hetznix01/post-install/wordpress.nix, which is a WordPress plugin,   #
  #  not part of fail2ban).                                              #
  #                                                                        #
  ##########################################################################

  services.fail2ban.jails = {
    "nginx-http-auth" = ''
      enabled      = true
      filter       = nginx-http-auth
      backend      = systemd
      journalmatch = _SYSTEMD_UNIT=nginx.service
      maxretry     = 5
      findtime     = 600
      bantime      = 3600
    '';

    "nginx-botsearch" = ''
      enabled  = true
      filter   = nginx-botsearch
      logpath  = /var/log/nginx/access.log
      maxretry = 3
      findtime = 600
      bantime  = 86400
    '';
  };
}
