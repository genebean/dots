{ config, username, ... }: {
  imports = [
    ../../../../system/common/linux/lets-encrypt.nix
    ../../../../system/common/linux/restic.nix
    ./matrix-synapse.nix
    ./nginx.nix
  ];

  mailserver = {
    enable = true;
    enableImap = false;
    enableImapSsl = false;
    fqdn = "mail.alt.technicalissues.us";
    domains = [
      "alt.technicalissues.us"
      "indianspringsbsa.org"
    ];
    forwards = {
      "webmaster@indianspringsbsa.org" = "gene+indianspringsbsa.org@geneliverman.com";
      "newsletter@indianspringsbsa.org" = "gene+indianspringsbsa.org@geneliverman.com";
      "@alt.technicalissues.us" = "gene+alt.technicalissues.us@geneliverman.com";
    };

    # Use Let's Encrypt certificates from Nginx
    certificateScheme = "acme";
  };

  # Cert for the mail server
  security.acme.certs."alt.technicalissues.us" = {
    extraDomainNames = [
      "mail.alt.technicalissues.us"
      "mail.indianspringsbsa.org"
    ];
    reloadServices = [
      "postfix.service"
    ];
  };

  services = {
    restic.backups.daily.paths = [
      "${config.users.users.${username}.home}/compose-files/owntracks"
      "/var/backup/postgresql"
      "/var/lib/uptime-kuma"
    ];
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_key.path;
      extraUpFlags = [
        "--advertise-exit-node"
        "--operator"
        "${username}"
        "--ssh"
      ];
      useRoutingFeatures = "both";
    };
  };

  sops = {
    age.keyFile = /home/${username}/.config/sops/age/keys.txt;
    defaultSopsFile = ../secrets.yaml;
    secrets = {
      local_git_config = {
        owner = "${username}";
        path = "/home/${username}/.gitconfig-local";
      };
      local_private_env = {
        owner = "${username}";
        path = "/home/${username}/.private-env";
      };
      matrix_secrets_yaml = {
        owner = config.users.users.matrix-synapse.name;
        restartUnits = ["matrix-synapse.service"];
      };
      matrix_homeserver_signing_key.owner = config.users.users.matrix-synapse.name;
      mqtt_recorder_pass.restartUnits = ["mosquitto.service"];
      owntracks_basic_auth = {
        owner = config.users.users.nginx.name;
        restartUnits = ["nginx.service"];
      };
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  };

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
