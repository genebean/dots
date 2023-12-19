{ pkgs, genebean-omp-themes, sops-nix, username, ... }: {
  home.stateVersion = "23.11";
  imports = [
    ../../common/all-cli.nix
    ../../common/all-gui.nix
    ../../common/all-darwin.nix
  ];
    
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
      local_git_config.path = "/Users/${username}/.gitconfig-local";
      local_private_env.path = "/Users/${username}/.private-env";
    };
  };

}
