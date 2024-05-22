{ pkgs, username, ... }: {
  home.packages = with pkgs; [
    home-manager
  ];

  sops = {
    age.keyFile = /home/${username}/.config/sops/age/keys.txt;
    defaultSopsFile = ../home-only/secrets.yaml;
#     secrets = {
#       local_git_config.path = "/home/${username}/.gitconfig-local";
#       local_private_env.path = "/home/${username}/.private-env";
#     };
  };
}

