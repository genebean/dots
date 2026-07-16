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
    fireflyiii = {
      port = 3005;
      openFirewall = true;
    };
    fireflyiii-importer = {
      port = 3006;
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
    youtarr = {
      port = 3087;
      openFirewall = true;
    };
    tube-archivist = {
      port = 8001;
      openFirewall = true;
    };
    wallabag = {
      port = 8090;
      openFirewall = true;
    };
    pocketbase = {
      port = 8091;
      openFirewall = true;
    };
    syncthing-gui = {
      port = 8384;
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

    # Firewalled TCP services continued
    social-reader-mcp = {
      port = 8787;
      openFirewall = true;
    };

    # Internal-only TCP services (proxied via nginx, not firewalled)
    pocket-id = {
      port = 1411;
    };
    immich = {
      port = 2283;
    };
    ytdlfin = {
      port = 8001;
    };
    cadvisor = {
      port = 8081;
    };
    jellyfin = {
      port = 8096;
    };
    victoriametrics = {
      port = 8428;
    };
    mealie = {
      port = 9000;
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
