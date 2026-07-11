{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.handbrake.enable {
    homebrew.casks = [ "handbrake-app" ];
  };
}
