{ config, pkgs, ... }:
let
  wpPlugins = pkgs.wordpressPackages.plugins;
  # wp-fail2ban ships its own fail2ban filter files — reference the store path
  # so we can symlink them into /etc/fail2ban/filter.d/ below.
  wpf2b = wpPlugins.wp-fail2ban;
in
{
  # Symlink the fail2ban filter files that ship with the wp-fail2ban plugin into
  # /etc/fail2ban/filter.d/ so fail2ban can reference them by name in the jails.
  # The plugin must be activated in WP admin for these filters to see any events.
  #
  # Filter severity levels:
  #   hard  — immediate/severe failures (unknown users, XML-RPC multicall, etc.)
  #   soft  — recoverable failures (wrong password, etc.)
  #   extra — informational events (comments, password resets)
  environment.etc = {
    "fail2ban/filter.d/wordpress-hard.conf".source = "${wpf2b}/filters.d/wordpress-hard.conf";
    "fail2ban/filter.d/wordpress-soft.conf".source = "${wpf2b}/filters.d/wordpress-soft.conf";
    "fail2ban/filter.d/wordpress-extra.conf".source = "${wpf2b}/filters.d/wordpress-extra.conf";
  };

  services = {
    # Fail2ban jails for WordPress auth events.
    # wp-fail2ban writes to syslog via openlog("wordpress", ...) which journald
    # captures as SYSLOG_IDENTIFIER=wordpress — no log file path needed.
    fail2ban.jails = {
      # Hard failures get an immediate 24-hour ban (1 strike = you're out).
      # Covers: unknown users, XML-RPC multicall, blocked users, etc.
      "wordpress-hard" = ''
        enabled      = true
        filter       = wordpress-hard
        backend      = systemd
        journalmatch = SYSLOG_IDENTIFIER=wordpress
        maxretry     = 1
        findtime     = 3600
        bantime      = 86400
      '';

      # Soft failures (wrong password, etc.) allow a small number of attempts
      # before banning — accommodates legitimate users who mistype.
      "wordpress-soft" = ''
        enabled      = true
        filter       = wordpress-soft
        backend      = systemd
        journalmatch = SYSLOG_IDENTIFIER=wordpress
        maxretry     = 5
        findtime     = 3600
        bantime      = 3600
      '';
    };

    # MariaDB — required by WordPress (it doesn't support PostgreSQL).
    # Conservative settings keep memory low on this shared VPS.
    mysql = {
      enable = true;
      package = pkgs.mariadb;
      settings.mysqld = {
        # Small buffer pool appropriate for a low-traffic Cub Scout site sharing
        # a VPS with several other services.
        innodb_buffer_pool_size = "64M";
        max_connections = 25;
      };
    };

    # Daily MariaDB backup matching the existing PostgreSQL backup schedule.
    # Unlike services.postgresqlBackup there is no backupAll option — any future
    # MariaDB-backed services must be added to this list explicitly.
    mysqlBackup = {
      enable = true;
      databases = [ "wordpress_138cubpack" ];
      calendar = "*-*-* 23:00:00";
    };

    nginx.virtualHosts = {
      # Extend the nginx virtual host that the WordPress module creates.
      #
      # SSL/TLS NOTE: cert issuance uses the Gandi DNS challenge (lets-encrypt.nix).
      # The cert cannot issue until 138cubpack.com is transferred to Gandi nameservers.
      # Until then nginx uses a self-signed placeholder and HTTPS shows a browser
      # warning — this is expected.  Transfer the domain to Gandi first, then point
      # the A/AAAA records at this host; the cert will issue automatically.
      "138cubpack.com" = {
        serverAliases = [ "www.138cubpack.com" ];
        enableACME = true;
        acmeRoot = null; # DNS challenge via Gandi — no webroot needed
        forceSSL = true;
        locations."= /xmlrpc.php" = {
          # Defense-in-depth: block xmlrpc.php at the nginx layer before PHP runs,
          # saving CPU.  The disable-xml-rpc plugin also disables it at the WP layer.
          # Note: requests blocked here will NOT be logged by wp-fail2ban (PHP never
          # runs), but the attacker still gets a 403 so the attack fails.
          return = "403";
        };
      };

      # Development vhost — available immediately because technicalissues.us is
      # already at Gandi, so the ACME cert issues without waiting for the
      # 138cubpack.com domain transfer.  Use this URL to set up and test WordPress
      # before cutting over the real domain.
      #
      # NOTE: WordPress will store 138cubpack.technicalissues.us as the site URL
      # during initial setup.  After real DNS is live, change Site URL + Home URL
      # in WP Admin → Settings → General to https://138cubpack.com.
      "138cubpack.technicalissues.us" = {
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        # Mirror the root, extraConfig (contains `index index.php;`), and locations
        # from the primary vhost so the two stay in sync automatically.
        root = config.services.nginx.virtualHosts."138cubpack.com".root;
        extraConfig = config.services.nginx.virtualHosts."138cubpack.com".extraConfig;
        locations = config.services.nginx.virtualHosts."138cubpack.com".locations;
      };
    };

    restic.backups.daily.paths = [
      "/var/backup/mysql"
      "/var/lib/wordpress/138cubpack.com/uploads"
    ];

    # WordPress site for Cub Scout Pack 138 (138cubpack.com).
    # The NixOS module handles PHP-FPM pool creation and nginx vhost wiring;
    # we extend both below.
    wordpress = {
      webserver = "nginx";
      sites."138cubpack.com" = {
        database = {
          # Unix socket auth: the PHP-FPM pool runs as the "wordpress" system user
          # and MariaDB authenticates by matching that Unix user — no password needed.
          createLocally = true;
          name = "wordpress_138cubpack";
          user = "wordpress";
        };

        # Persistent uploads directory outside the read-only Nix store.
        uploadsDir = "/var/lib/wordpress/138cubpack.com/uploads";

        # Plugins installed by Nix (copied into wp-content/plugins at deploy time).
        # IMPORTANT: activate them in WP admin after first deploy, in this order:
        #   1. wp-fail2ban     — starts logging auth events to syslog immediately
        #   2. disable-xml-rpc — disables XML-RPC at the WordPress layer
        #   3. simple-login-captcha — adds math captcha to the login page
        plugins = {
          inherit (wpPlugins) disable-xml-rpc;
          inherit (wpPlugins) wp-fail2ban;
          inherit (wpPlugins) simple-login-captcha;
        };

        settings = {
          # Force WP admin to require HTTPS even when accessed over HTTP.
          FORCE_SSL_ADMIN = true;
        };

        extraConfig = ''
          # Tell WordPress it is behind an HTTPS-terminating reverse proxy (nginx).
          # Without this, WordPress generates http:// URLs for admin redirects.
          $_SERVER['HTTPS'] = 'on';
        '';

        # Spawn PHP workers only on demand; reclaim memory when idle.
        # 4 workers is plenty for a low-traffic pack site.
        poolConfig = {
          "pm" = "ondemand";
          "pm.max_children" = 4;
          "pm.process_idle_timeout" = "10s";
        };
      };
    };
  };
}
