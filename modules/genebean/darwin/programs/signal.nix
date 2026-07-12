{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.signal.enable {
    homebrew.casks = [ "signal" ];
  };
}
