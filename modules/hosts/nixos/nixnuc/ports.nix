# Entries within each section are sorted by port number in ascending order.
{
  config.genebean.ports = {
    # Override global photon default: open the firewall on this host
    photon = {
      openFirewall = true;
    };

    # Firewalled TCP services
    smb-netbios-session = {
      port = 139;
      openFirewall = true;
    };
    smb = {
      port = 445;
      openFirewall = true;
    };
    pocket-id = {
      port = 1411;
      openFirewall = true;
    };
    immich = {
      port = 2283;
      openFirewall = true;
    };
    psitransfer = {
      port = 3000;
      openFirewall = true;
    };
    immich-kiosk = {
      port = 3001;
      openFirewall = true;
    };
    grafana = {
      port = 3002;
      openFirewall = true;
    };
    karakeep = {
      port = 3003;
      openFirewall = true;
    };
    cup-collector = {
      port = 3010;
      openFirewall = true;
    };
    forgejo = {
      port = 3030;
      openFirewall = true;
    };
    buzz-relay = {
      port = 3033;
      openFirewall = true;
    };
    youtarr = {
      port = 3087;
      openFirewall = true;
    };
    # Matches bd's own --server-port default (3307, confirmed via `bd init
    # --help`) - clients connecting with just --server-host need no
    # --server-port override. Not actually internet-exposed despite
    # openFirewall=true: nixnuc sits behind a physical/hardware firewall
    # that only forwards 80/443 (nginx's) from the internet, confirmed
    # directly by the repo owner - NixOS's own software firewall being
    # open here doesn't change real-world reachability.
    dolt-beads = {
      port = 3307;
      openFirewall = true;
    };
    tube-archivist = {
      port = 8001;
      openFirewall = true;
    };
    # Shares port 8001 with tube-archivist above - pre-existing, not
    # introduced by this change. Only one is actually bound at a time on
    # this host; left as found rather than renumbered speculatively.
    ytdlfin = {
      port = 8001;
      openFirewall = true;
    };
    # Not 8080 (atticd's own upstream default) - that's crowdsec's LAPI
    # port on this host, registered fleet-wide in
    # modules/genebean/nixos/ports.nix as crowdsec-lapi. Firewalled (not
    # internal-only) since pigate now proxies to this over the services
    # VLAN rather than nginx being co-located on this host.
    attic = {
      port = 8082;
      openFirewall = true;
    };
    pocketbase = {
      port = 8091;
      openFirewall = true;
    };
    jellyfin = {
      port = 8096;
      openFirewall = true;
    };
    syncthing-gui = {
      port = 8384;
      openFirewall = true;
    };
    victoriametrics = {
      port = 8428;
      openFirewall = true;
    };
    gitdeck = {
      port = 8765;
      openFirewall = true;
    };
    atuin = {
      port = 8888;
      openFirewall = true;
    };
    pinchflat = {
      port = 8945;
      openFirewall = true;
    };
    audiobookshelf = {
      port = 13378;
      openFirewall = true;
    };
    mealie = {
      port = 9000;
      openFirewall = true;
    };
    # LAN-only for now by design, not a security gap to fix later - Scotty
    # has no built-in authentication at all, so this stays off nginx/443
    # (shared with internet-facing vhosts) until an auth layer exists.
    scotty = {
      port = 9005;
      openFirewall = true;
    };

    # Firewalled TCP services continued
    # pigate's buzz vhost proxies /pair here directly over the services
    # VLAN now, not through nginx co-located on this host.
    buzz-pair-relay = {
      port = 5000;
      openFirewall = true;
    };
    rustfs-console = {
      port = 9011;
      openFirewall = true;
    };

    # NOT openFirewall (that would open it fleet-wide) - restricted to
    # tcan-left (192.168.20.191) only, via a dedicated iptables rule in
    # this host's own default.nix, not the generic allowlist. LAN-only by
    # design (never internet-facing), so it stays on this host rather than
    # going through pigate's DMZ edge - that would require routing
    # tcan-left's LAN traffic through a new LAN->DMZ firewall rule for no
    # benefit, since this was never part of the internet-facing attack
    # surface pigate exists to protect. See dots#760 for generalizing this
    # pattern once there's a second case.
    social-reader-mcp-https = {
      port = 8443;
    };
    # Loopback-only (bound to 127.0.0.1 in the owning module, no firewall
    # entry needed at all) - hermes-agent-fleet-plan issue 37. nginx on
    # social-reader-mcp-https (above) is the only path in.
    social-reader-mcp = {
      port = 8787;
    };
    # Loopback-only (bound to 127.0.0.1 in the owning module, no firewall
    # entry needed at all): the S3 API. Buzz is the only consumer and runs
    # on this same host.
    rustfs-api = {
      port = 9010;
    };
    # Loopback-only: local health/metrics checks only, no external consumer.
    buzz-health = {
      port = 9101;
    };
    buzz-metrics = {
      port = 9102;
    };
    # Loopback-only: the CI deploy-trigger endpoint. Reached through nginx's
    # /hooks/ location on the newspaper vhost, same pattern as
    # social-reader-mcp-https/social-reader-mcp above.
    newspaper-webhook = {
      port = 9103;
    };
    # Loopback-only: oauth2-proxy gating the newspaper vhost against
    # PocketID. nginx is the only consumer, same host.
    newspaper-oauth2-proxy = {
      port = 9104;
    };

    # Internal-only TCP services (same-host consumers only - nothing pigate
    # needs to reach over the services VLAN).
    # cadvisor: scraped by victoriametrics, same host, no other consumer.
    cadvisor = {
      port = 8081;
    };
    # newspaper: pigate reaches this via nixnuc's own trimmed nginx on port
    # 80 (Host-header routing), not this port directly - see default.nix's
    # "newspaper.${home_domain}" vhost.
    newspaper = {
      port = 9002;
    };

    # UDP services
    smb-netbios-ns = {
      port = 137;
      protocol = "udp";
      openFirewall = true;
    };
    smb-netbios-dgram = {
      port = 138;
      protocol = "udp";
      openFirewall = true;
    };
    jellyfin-ssdp = {
      port = 1900;
      protocol = "udp";
      openFirewall = true;
    };
    jellyfin-discovery = {
      port = 7359;
      protocol = "udp";
      openFirewall = true;
    };
  };
}
