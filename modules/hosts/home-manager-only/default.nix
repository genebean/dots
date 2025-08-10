{ config, pkgs, system, username, ... }: {
  home.stateVersion = "25.05";
  home.packages = with pkgs; [
    age
    home-manager
    sops
    ssh-to-age
  ];

  # home-manager switch --flake ~/repos/dots
  programs.zsh.shellAliases = {
    nixdiff = "cd ~/repos/dots && home-manager build --flake .#${username}-${system} && nvd diff /run/current-system result";
    nixup = "home-manager switch --flake ~/repos/dots#${username}-${system}";
  };

  sops = {
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      local_git_config.path = "${config.home.homeDirectory}/.gitconfig-local";
      local_private_env.path = "${config.home.homeDirectory}/.private-env";
    };
  };
}
