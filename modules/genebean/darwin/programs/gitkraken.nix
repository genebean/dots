{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.gitkraken.enable {
    homebrew.casks = [
      "gitkraken"
      "gitkraken-cli"
    ];
  };
}
