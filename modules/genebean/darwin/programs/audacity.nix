{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.audacity.enable {
    homebrew.casks = [ "audacity" ];
  };
}
