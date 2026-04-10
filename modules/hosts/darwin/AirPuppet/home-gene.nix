{ username, ... }:
{
  home.stateVersion = "23.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_private_env.path = "/Users/${username}/.private-env";
    };
  };
}
