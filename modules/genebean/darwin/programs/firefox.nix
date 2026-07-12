{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.firefox.enable {
    homebrew.casks = [ "firefox" ];
  };
}
