{ config, ... }: {
  home.stateVersion = "23.11";

  programs = {
    go = {
      enable = true;
      env.GOPATH = "${config.home.homeDirectory}/go";
    };
    k9s.enable = true;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      i2cssh_config.path = "${config.home.homeDirectory}/.i2csshrc";
      local_git_config.path = "${config.home.homeDirectory}/.gitconfig-local";
      local_private_env.path = "${config.home.homeDirectory}/.private-env";
      user_nix_conf.path = "${config.home.homeDirectory}/.config/nix/nix.conf";
    };
  };
}
