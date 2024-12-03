{ config, pkgs, hostname, username, ... }: {
  home.packages = with pkgs; [
    home-manager
  ];

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ../hosts/${hostname}/secrets.yaml;
    secrets = {
      local_git_config.path = "${config.users.users.${username}.home}/.gitconfig-local";
      local_private_env.path = "${config.users.users.${username}.home}/.private-env";
    };
  };
}

