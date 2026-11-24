{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  home_domain = "home.technicalissues.us";
  # nixnuc's services-VLAN IP - where every backend app this host proxies
  # to actually listens. Not nixnuc's general LAN IP: that's a deliberate
  # segmentation choice (see modules/hosts/nixos/nixnuc/default.nix's
  # vlan2332 interface) so DMZ-originated traffic never touches the
  # trusted LAN directly, only this narrower UniFi-firewalled zone.
  backend_ip = "192.168.23.130";
in
{
  imports = [
    ./disko.nix
    # nixnuc's backend app ports (audiobookshelf, jellyfin, immich, ...) -
    # imported directly rather than duplicating every port number here or
    # promoting this host-pair-only table to the fleet-wide registry.
    ../nixnuc/ports.nix
    ../../../shared/nixos/crowdsec.nix
    ../../../shared/nixos/fail2ban-nginx.nix
    ../../../shared/nixos/lets-encrypt.nix
  ];

  system.stateVersion = "26.05";

  boot = {
    loader.raspberry-pi = {
      enable = true;
      variant = "4";
      # bootloader defaults to "uboot" for variant 4
    };
    # SD card write endurance: targeted tmpfs for the hot paths (CrowdSec/
    # fail2ban's SQLite DBs, nginx's logs, below), not full impermanence -
    # this is a gateway, not a kiosk.
    tmp.useTmpfs = true;
    kernel.sysctl."net.ipv4.ip_forward" = 0; # pigate is not a router itself
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  # Not part of genebean.kiosk-hardware: nixpkgs.overlays helps construct
  # `pkgs` itself, so gating it behind a cfg.enable check creates a genuine
  # circular dependency - see kiosk-gene-desk/default.nix, which hit this
  # first. Generic nixos-raspberrypi fix, not kiosk-specific; stays
  # per-host, unconditional.
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # Native builds on a Pi 4 are slow - offload to the fleet's aarch64
  # Hetzner VPS, same as kiosk-gene-desk.
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "hetznix02.technicalissues.us";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
        ];
        sshUser = "gene";
        sshKey = "/root/.ssh/id_ed25519";
      }
    ];
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  ##########################################################################
  #                                                                        #
  #  DMZ networking: a dedicated untagged access port on the UniFi, no    #
  #  VLAN tagging needed here. pigate is not a router itself - the UniFi  #
  #  does all forwarding between zones, including DMZ -> Services for     #
  #  every backend proxied below.                                         #
  #                                                                        #
  ##########################################################################
  networking = {
    useDHCP = false;
    networkmanager.enable = false;
    useNetworkd = true;
    # end0, not eth0 - confirmed live via `ip a` on real hardware: Pi
    # 4/BCM2711's onboard NIC enumerates under this name with NixOS's
    # predictable interface naming, not the traditional eth0.
    interfaces.end0.ipv4.addresses = [
      {
        address = "192.168.23.2";
        prefixLength = 30;
      }
    ];
    defaultGateway = {
      address = "192.168.23.1";
      interface = "end0";
    };
    nameservers = [ "192.168.23.1" ]; # UniFi as DNS server

    firewall = {
      allowedTCPPorts = lib.pipe config.genebean.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "tcp"))
        (map (e: e.port))
      ];
      allowedUDPPorts = lib.pipe config.genebean.ports [
        builtins.attrValues
        (builtins.filter (e: e.openFirewall && e.protocol == "udp"))
        (map (e: e.port))
      ];
    };
  };

  ##########################################################################
  #                                                                        #
  #  journald volatile since nothing here needs to survive a reboot and   #
  #  logs ship elsewhere soon anyway. ACME renewal writes are low-        #
  #  frequency (~60 days) and stay on the real f2fs root along with /etc  #
  #  and NixOS generations.                                               #
  #                                                                        #
  #  /var/lib/crowdsec deliberately NOT tmpfs, unlike fail2ban/nginx       #
  #  below - confirmed live this breaks CrowdSec outright. It expects to   #
  #  bootstrap its own directory tree once (data/, data/hub/ collection    #
  #  definitions, etc.) and keep it across reboots; wiping the whole       #
  #  thing every boot doesn't just lose state, CrowdSec doesn't know how   #
  #  to recreate the structure from scratch and fails to start entirely.   #
  #  The actual write-heavy part is the decisions/alerts sqlite db, not    #
  #  the mostly-static hub/ data - in dry-run mode (no community          #
  #  blocklist, local-decisions-only) that write volume is low enough not  #
  #  to need this. Revisit with a narrower fix (e.g. just the db file) if  #
  #  SD wear turns out to be a real measured problem later.               #
  #                                                                        #
  ##########################################################################
  # Confirmed live: the nixpkgs-unstable crowdsec module's various units
  # (crowdsec-setup.service, crowdsec-firewall-bouncer-register.service)
  # don't reliably create /var/lib/crowdsec themselves before needing it -
  # this had only ever worked by accident because the now-removed tmpfs
  # mount above guaranteed the directory existed as a side effect.
  # Type `d` (create-if-missing), not `z` - no "unsafe path transition"
  # concern here since /var/lib is root-owned throughout, unlike the
  # /home/<user>/.config case elsewhere in this file.
  systemd.tmpfiles.rules = [
    "d /var/lib/crowdsec 0750 crowdsec crowdsec -"
    "d /var/lib/crowdsec/data 0750 crowdsec crowdsec -"
  ];

  fileSystems = {
    "/var/lib/fail2ban" = {
      fsType = "tmpfs";
      options = [
        "size=32M"
        "mode=0750"
      ];
    };
    "/var/log/nginx" = {
      fsType = "tmpfs";
      # uid/gid required - same bug class as crowdsec's tmpfs above,
      # confirmed live: without this the mount defaults to root:root and
      # logrotate's own permission-check phase (which runs as nginx:nginx
      # for this log stanza) can't even stat the files, failing
      # logrotate-checkconf.service. nginx itself is unaffected (its
      # master process runs as root and writes the files directly), this
      # only broke the periodic rotation check.
      options = [
        "size=128M"
        "mode=0750"
        "uid=nginx"
        "gid=nginx"
      ];
    };
  };

  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=128M
  '';

  # Every vhost this host's own nginx serves, pointed back at this host's
  # own DMZ IP - generated rather than hand-added one at a time, same
  # workaround nixnuc's existing id.${home_domain} extraHosts entry uses:
  # nginx doesn't route SNI correctly on loopback, and each vhost's public
  # hostname resolves to this host's own public IP, so a same-host caller
  # (pigate's own vmagent push below, today; anything else later) would
  # otherwise depend on the UniFi's hairpin NAT behavior instead of just
  # reaching this host's own nginx directly.
  networking.extraHosts = lib.concatMapStrings (name: "192.168.23.2 ${name}\n") (
    builtins.attrNames config.services.nginx.virtualHosts
  );

  services = {
    fail2ban.enable = true; # jails come from ../../../shared/nixos/fail2ban-nginx.nix
    # Matches every other NixOS host's explicit declaration (nixnuc, star1,
    # tcan-left, rainbow-planet) - already nixpkgs-26.05's default without
    # this, but that's an implicit, undeclared default worth pinning down
    # explicitly rather than relying on it silently staying that way.
    resolved.enable = true;

    # Same fleet-wide push pattern every other host uses (see
    # kiosk-entryway/monitoring.nix) - shared vmagent_push_pw secret, same
    # public hostname/endpoint, no bespoke auth-bypass. pigate becomes a
    # recipient of modules/shared/secrets.yaml like every other host once
    # onboarded (README.md's "Adding a NixOS host" step 8), so this needs
    # no new secret of its own.
    prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      inherit (config.genebean.ports.node-exporter) port;
    };
    vmagent = {
      enable = true;
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "node";
            static_configs = [
              { targets = [ "127.0.0.1:${toString config.genebean.ports.node-exporter.port}" ]; }
            ];
            relabel_configs = [
              {
                target_label = "instance";
                replacement = config.networking.hostName;
              }
            ];
          }
        ];
      };
      remoteWrite = {
        basicAuthUsername = "metricsshipper";
        basicAuthPasswordFile = config.sops.secrets.vmagent_push_pw.path;
        url = "https://monitoring.${home_domain}/remotewrite";
      };
    };

    ##########################################################################
    #                                                                        #
    #  nginx: edge/TLS termination for the whole fleet's public vhosts.     #
    #  Every vhost proxies straight to the backend app's own port on       #
    #  nixnuc's services-VLAN IP, EXCEPT nextcloud/newspaper/podcasts,      #
    #  which proxy to nixnuc's own (trimmed, plain-HTTP) nginx on port 80   #
    #  instead - those three assume something co-located with nginx        #
    #  itself (php-fpm socket, oauth2-proxy's nginx integration, local      #
    #  static files) that can't just become a plain app-port proxy. See    #
    #  modules/hosts/nixos/nixnuc/default.nix for that trimmed nginx.       #
    #                                                                        #
    ##########################################################################
    nginx = {
      enable = true;
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

        # Rate-limit the ytdlfin health endpoint so unauthenticated bots
        # can't hammer it. Uptime Kuma polls once per minute; 6r/m gives
        # comfortable headroom while still blocking floods.
        limit_req_zone $binary_remote_addr zone=ytdlfin_health:1m rate=6r/m;

        # Mealie has no built-in rate limiting at all on its API (confirmed
        # from Mealie's own security docs, which explicitly recommend doing
        # this at the reverse proxy) - no fail2ban filter needed/available,
        # this covers the same ground at the nginx layer instead.
        limit_req_zone $binary_remote_addr zone=mealie_login:1m rate=10r/m;

        # General per-IP connection cap, fleet-wide (not endpoint-specific
        # like the two zones above) - this is the internet-facing side of
        # a resource-constrained Pi 4, so a basic connection-flood defense
        # belongs here regardless of which vhost gets hit. 40 is well above
        # what a browser or API client legitimately opens per origin.
        limit_conn_zone $binary_remote_addr zone=perip:10m;
        limit_conn perip 40;
      '';
      virtualHosts = {
        "${home_domain}" = {
          default = true;
          serverAliases = [
            "nix-tester.${home_domain}"
          ];
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/" = {
            return = "200 '<h1>Hello world ;)</h1>'";
            extraConfig = ''
              add_header Content-Type text/html;
            '';
          };
          locations."/server_status" = {
            extraConfig = ''
              stub_status;
              allow 127.0.0.1;
              deny all;
            '';
          };
        };
        "ab.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyWebsockets = true;
          locations."/".proxyPass =
            "http://${backend_ip}:${toString config.genebean.ports.audiobookshelf.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "attic.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.attic.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "atuin.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.atuin.port}";
        };
        "buzz.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.buzz-relay.port}";
              proxyWebsockets = true;
            };
            "/pair" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.buzz-pair-relay.port}";
              proxyWebsockets = true;
            };
          };
        };
        "git.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.forgejo.port}";
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
        "id.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.pocket-id.port}";
          extraConfig = ''
            proxy_busy_buffers_size   512k;
            proxy_buffers           4 512k;
            proxy_buffer_size         256k;
          '';
        };
        "immich.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.immich.port}";
          locations."/".proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout       600s;
          '';
        };
        "immich-kiosk.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          basicAuthFile = config.sops.secrets.immich_kiosk_basic_auth.path;
          locations."/".proxyPass =
            "http://${backend_ip}:${toString config.genebean.ports.immich-kiosk.port}";
          locations."/".proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            send_timeout       600s;
          '';
        };
        "karakeep.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${backend_ip}:${toString config.genebean.ports.karakeep.port}";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 100M;
          '';
        };
        "jellyfin.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.jellyfin.port}";
              extraConfig = ''
                proxy_buffering off;
                proxy_set_header X-Forwarded-Protocol $scheme;
              '';
            };
            "/socket" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.jellyfin.port}";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header X-Forwarded-Protocol $scheme;
              '';
            };
          };
          extraConfig = ''
            client_max_body_size 20M;
          '';
        };
        "mealie.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.mealie.port}";
            "= /api/auth/token" = {
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.mealie.port}/api/auth/token";
              extraConfig = ''
                limit_req zone=mealie_login burst=3 nodelay;
              '';
            };
          };
          extraConfig = ''
            client_max_body_size 10M;
          '';
        };
        "monitoring.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations = {
            "/grafana/".proxyPass =
              "http://${backend_ip}:${toString config.genebean.ports.grafana.port}/grafana/";
            # The fleet's existing metrics-ingestion path: other hosts'
            # vmagents push here (over Tailscale, unchanged by this move).
            # pigate's own metrics do NOT go through this - see
            # services.vmagent above.
            "/remotewrite" = {
              basicAuthFile = config.sops.secrets.nginx_basic_auth.path;
              proxyPass = "http://${backend_ip}:${toString config.genebean.ports.victoriametrics.port}/api/v1/write";
              proxyWebsockets = true;
            };
          };
        };
        # Proxies to nixnuc's own trimmed nginx (plain HTTP, services VLAN)
        # instead of a backend app port directly - oauth2-proxy's nginx
        # integration (newspaper.nix) assumes it's co-located with the
        # nginx terminating this vhost, which is no longer pigate. See
        # modules/hosts/nixos/nixnuc/default.nix.
        "newspaper.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:80";
        };
        # Proxies to nixnuc's own trimmed nginx - services.nextcloud.nginx
        # assumes a co-located php-fpm socket, so Nextcloud keeps its own
        # local vhost on nixnuc rather than becoming a plain app-port proxy.
        "nextcloud.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:80";
        };
        # Proxies to nixnuc's own trimmed nginx - podcasts serves static
        # files straight off nixnuc's local disk, so it keeps its own local
        # vhost (basic auth enforced there too) rather than becoming a
        # plain app-port proxy.
        "podcasts.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:80";
        };
        # social-reader-mcp-https stays on nixnuc (see its default.nix) -
        # it's LAN-only (restricted to tcan-left by source IP, never
        # internet-facing to begin with), so it has no business going
        # through the DMZ edge at all. Moving it here was a mistake in an
        # earlier pass of this work; reverted.
        "ytdlfin.${home_domain}" = {
          listen = [
            {
              inherit (config.genebean.ports.https) port;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          locations."/".proxyPass = "http://${backend_ip}:${toString config.genebean.ports.ytdlfin.port}";
          locations."= /health" = {
            proxyPass = "http://${backend_ip}:${toString config.genebean.ports.ytdlfin.port}";
            extraConfig = ''
              limit_req zone=ytdlfin_health burst=3 nodelay;
            '';
          };
        };
      };
    };
  };

  ##########################################################################
  #                                                                        #
  #  Resource limits / OOM protection. This is a single-purpose,          #
  #  internet-facing Pi 4 with modest RAM - a flood or a runaway nginx     #
  #  worker shouldn't be able to take down SSH management access along    #
  #  with it. Deliberately NOT touching crowdsec-firewall-bouncer's own    #
  #  sandboxing here: it genuinely needs CAP_NET_ADMIN/CAP_NET_RAW to      #
  #  manage nftables, and over-sandboxing it would just break it. The     #
  #  tmpfs `size=` caps above (fileSystems."/var/lib/fail2ban" etc.) are   #
  #  already a resource bound in their own right - a flood that fills     #
  #  nginx's log tmpfs fails that write, it doesn't balloon past the cap. #
  #                                                                        #
  ##########################################################################
  systemd.services = {
    nginx.serviceConfig = {
      MemoryMax = "512M";
      # Let nginx be the first thing killed under memory pressure, not
      # sshd/crowdsec/fail2ban below - it's the most replaceable (systemd
      # restarts it) and the most likely to be the actual source of
      # pressure in the first place (a flood).
      OOMScoreAdjust = 200;
    };
    sshd.serviceConfig.OOMScoreAdjust = -500; # protect management access

    # Seeding .config/sops/age/keys.txt via --extra-files (needed for
    # activation to succeed at all on first boot - see the sops comment
    # below) creates /home/gene, .config, .config/sops, and
    # .config/sops/age as root:root before NixOS's own home-directory
    # creation runs. A systemd.tmpfiles.rules `z` fix does NOT work around
    # this, confirmed live: systemd-tmpfiles has a hardcoded "unsafe path
    # transition" refusal (gene-owned parent -> root-owned child looks
    # like a symlink-attack vector) with no override, so the rule silently
    # never applies. A plain chown isn't subject to that refusal at all -
    # it's specific to systemd-tmpfiles' own codepath, not a kernel/
    # filesystem restriction - so a oneshot running one directly works.
    # Conditional and idempotent: only touches anything if .config is
    # still root-owned, so it's a no-op on every boot after the first.
    fix-config-ownership = {
      description = "Fix /home/${username}/.config ownership if extra-files left it root-owned";
      wantedBy = [ "multi-user.target" ];
      before = [ "home-manager-${username}.service" ];
      after = [ "local-fs.target" ];
      unitConfig.ConditionPathExists = "/home/${username}/.config";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        config_dir="/home/${username}/.config"
        owner="$(${pkgs.coreutils}/bin/stat -c %U "$config_dir")"
        if [ "$owner" = "root" ]; then
          ${pkgs.coreutils}/bin/chown -R ${username}:users "$config_dir"
        fi
      '';
    };
  };

  ##########################################################################
  #                                                                        #
  #  Secrets. NOT generated here - no age key, no secrets.yaml content.   #
  #  Per standing policy, secrets are generated/authored on or for the    #
  #  target host directly, not by an agent mid-session. Before this host  #
  #  evaluates/builds, author modules/hosts/nixos/pigate/secrets.yaml     #
  #  (`sops modules/hosts/nixos/pigate/secrets.yaml`) with:               #
  #  immich_kiosk_basic_auth, nginx_basic_auth.                           #
  #                                                                        #
  #  gandi_dns_pat is NOT a pigate-local secret: this host reuses the     #
  #  existing shared modules/shared/secrets.yaml gandi_dns_pat (same      #
  #  token ddclient and nixnuc's direct-ACME certs already use), picked   #
  #  up automatically from lets-encrypt.nix's own sops.secrets            #
  #  declaration - no override needed here. Gandi's PAT permission model  #
  #  can't scope narrower than whole-domain DNS write for what lego's     #
  #  gandiv5 provider currently calls (confirmed against its source:      #
  #  PUT /v5/livedns/domains/{domain}/records/{name}/TXT), so a separate  #
  #  token for pigate wouldn't actually reduce the permission surface     #
  #  today. Gandi does have a purpose-built, more narrowly-scoped         #
  #  "ownership verification record" endpoint for exactly this ACME DNS-  #
  #  01 use case, and lego gained support for it in go-acme/lego#3391     #
  #  (merged 2026-11-18, targeting the v5.7 release) - too recent to be   #
  #  in whatever lego version nixpkgs-26.05 vendors. Revisit minting a    #
  #  separate, narrowly-scoped pigate token once nixpkgs picks up         #
  #  lego 5.7+ (tracked on agents-beads-collaboration-g4f).               #
  #                                                                        #
  ##########################################################################
  sops = {
    # Matches every other host's convention. Confirmed live (first
    # install, 2026-11-23) that sops-install-secrets treats a configured-
    # but-missing keyFile as fatal even when the sshKeyPaths fallback
    # (modules/hosts/nixos/default.nix) already succeeded at importing a
    # valid identity - both setupSecrets and setupSecretsForUsers failed
    # activation as a result, because this path was never actually seeded
    # via --extra-files on that attempt. Must be seeded (same derived
    # private key used to author pigate/secrets.yaml) for activation to
    # succeed, same as every other host apparently already has in place.
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      immich_kiosk_basic_auth = {
        owner = config.users.users.nginx.name;
        restartUnits = [ "nginx.service" ];
      };
      # Matches nixnuc/bigboy's own declaration exactly - genebean
      # tooling expects this at login (confirmed live: "~/.private-env is
      # missing" errored at console login before this was added). Content
      # was already pre-provisioned in pigate/secrets.yaml.
      local_private_env = {
        owner = "${username}";
        path = "${config.users.users.${username}.home}/.private-env";
      };
      nginx_basic_auth = {
        owner = config.users.users.nginx.name;
        restartUnits = [ "nginx.service" ];
      };
      # neededForUsers: hashedPasswordFile consumers need this decrypted
      # during the early user-setup phase of activation (a separate,
      # earlier path than sops-nix's normal /run/secrets/), not the usual
      # systemd-service activation step.
      user_password_hash.neededForUsers = true;
      # Shared fleet-wide secret (kiosk-entryway/monitoring.nix uses the
      # same one) - pigate is a recipient of this file once onboarded, no
      # new secret content needed.
      vmagent_push_pw = {
        owner = "vmagent";
        restartUnits = [ "vmagent.service" ];
        sopsFile = ../../../shared/secrets.yaml;
      };
    };
  };

  users = {
    # Brand-new host: not yet known to private-flake's per-host wiring
    # (see the ssh-keys module every host imports via
    # lib/mkNixosHost.nix), so the base account needs an explicit
    # declaration here rather than relying on that to supply it, unlike
    # the fleet's existing hosts.
    users.${username} = {
      isNormalUser = true;
      description = "Gene Liverman";
      extraGroups = [ "wheel" ];
      # Enforced on every activation (unlike initialHashedPassword/
      # initialPassword, which only apply once on first account creation
      # and never correct local drift afterward) - no other fleet host
      # does this, since they rely purely on SSH-key auth
      # (private-flake's ssh-keys.nix) with no login password at all.
      # pigate gets one anyway: physical console access matters more for
      # a DMZ bastion with no VPN fallback (see the plan's break-glass
      # access note), so the console password shouldn't be able to drift
      # from what's declared here.
      hashedPasswordFile = config.sops.secrets.user_password_hash.path;
    };

    # services.vmagent doesn't create its own service user - matches
    # kiosk-entryway/monitoring.nix's declaration exactly.
    users.vmagent = {
      isSystemUser = true;
      group = "vmagent";
    };
    groups.vmagent = { };
  };
}
