{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.obs.enable {
    homebrew.casks = [ "obs" ];
  };
}
