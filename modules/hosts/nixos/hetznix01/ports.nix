{
  config.dots.ports = {
    # Firewalled TCP services (email)
    smtp = {
      port = 25;
      openFirewall = true;
    };
    imap = {
      port = 143;
      openFirewall = true;
    };
    smtp-tls = {
      port = 465;
      openFirewall = true;
    };
    smtp-starttls = {
      port = 587;
      openFirewall = true;
    };
    imaps = {
      port = 993;
      openFirewall = true;
    };

    # MQTT (via EMQX container)
    mqtt = {
      port = 1883;
      openFirewall = true;
    };
    mqtt-tls = {
      port = 8883;
      openFirewall = true;
    };
    mqtt-ws = {
      port = 9001;
      openFirewall = true;
    };

    # Bitcoin / Lightning (proxied to umbrel on tailnet)
    bitcoin-core = {
      port = 8333;
      openFirewall = true;
    };
    bitcoin-knots = {
      port = 9333;
      openFirewall = true;
    };
    lnd = {
      port = 9735;
      openFirewall = true;
    };

    # Matrix federation listener (nginx terminates, proxies to matrix-synapse)
    matrix-federation = {
      port = 8448;
      openFirewall = true;
    };

    # Internal-only TCP services (proxied via nginx, not firewalled)
    matrix-synapse = {
      port = 8008;
    };
    owntracks-frontend = {
      port = 8082;
    };
    owntracks-recorder = {
      port = 8083;
    };
    plausible = {
      port = 8001;
    };
    uptime-kuma = {
      port = 3001;
    };
    collabora = {
      port = 9980;
    };
    emqx-admin = {
      port = 18083;
    };
  };
}
