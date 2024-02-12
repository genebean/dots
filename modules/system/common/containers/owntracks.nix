{ ... }: {
  # Ideas from https://madison-technologies.com/take-your-nixos-container-config-and-shove-it/
  virtualisation.oci-containers.containers = {
    # See https://github.com/owntracks/frontend
    ot-frontend = {
      image = "owntracks/frontend";
    };
    # See https://github.com/owntracks/docker-recorder
    ot-recorder = {
      image = "owntracks/recorder";
    };
  };
}
