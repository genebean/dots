{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.onlyoffice.enable {
    homebrew.casks = [ "onlyoffice" ];
  };
}
