{ config, ... }: let
  volume_base = "/orico/psitransfer";
  http_port = "3000";
  psitransfer_dot_env = "${config.sops.secrets.psitransfer_dot_env.path}";
in {

  #############################################################################
  # My intent as of now is to only make this available to the outside world   #
  # on an as-needed basis, maybe via Tailscale Funnel.                        #
  # For example: $ tailscale funnel localhost:3000                            #
  #############################################################################

  sops.secrets.psitransfer_dot_env = {
    sopsFile = ../secrets.yaml;
    restartUnits = [
      "podman-psitransfer.service"
    ];
  };

  virtualisation.oci-containers.containers = {
    "psitransfer" = {
      autoStart = true;
      image = "psitrax/psitransfer";
      environmentFiles = [ psitransfer_dot_env ];
      ports = [ "${http_port}:3000" ];
      volumes = [
        "${volume_base}/data:/data"
      ];
    };
  };
}

