{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.meld.enable {
    homebrew.casks = [ "meld" ];
  };
}
