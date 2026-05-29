{
  config.dots.ports = {
    # Override global photon default: open the firewall on this host
    photon = {
      openFirewall = true;
    };

    # Firewalled TCP services
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
    syncthing-gui = {
      port = 8384;
      openFirewall = true;
    };
    atuin = {
      port = 8888;
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
    pinchflat = {
      port = 8945;
      openFirewall = true;
    };
    audiobookshelf = {
      port = 13378;
      openFirewall = true;
    };

    # Internal-only TCP services (proxied via nginx, not firewalled)
    pocket-id = {
      port = 1411;
    };
    immich = {
      port = 2283;
    };
    cadvisor = {
      port = 8081;
    };
    victoriametrics = {
      port = 8428;
    };
    jellyfin = {
      port = 8096;
    };
    mealie = {
      port = 9000;
    };

    # UDP services
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
