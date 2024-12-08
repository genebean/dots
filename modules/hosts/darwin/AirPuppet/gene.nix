{ username, ... }: {
  home.stateVersion = "23.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_git_config.path = "/Users/${username}/.gitconfig-local";
      local_private_env.path = "/Users/${username}/.private-env";
    };
  };
}
