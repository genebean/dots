{ config, username, ... }: {
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
}

