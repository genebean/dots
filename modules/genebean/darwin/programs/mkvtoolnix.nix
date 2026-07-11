{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.mkvtoolnix.enable {
    homebrew.casks = [ "mkvtoolnix-app" ];
  };
}
