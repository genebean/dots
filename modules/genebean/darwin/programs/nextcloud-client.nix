{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.nextcloud-client.enable {
    homebrew.casks = [ "nextcloud" ];
  };
}
