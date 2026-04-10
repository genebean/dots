{ username, ... }:
{
  home.stateVersion = "23.11";

  programs = {
    go = {
      enable = true;
      goPath = "go";
    };
    k9s.enable = true;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_private_env.path = "/Users/${username}/.private-env";
    };
  };
}
