{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.caffeine.enable {
    homebrew.casks = [ "keepingyouawake" ];
  };
}
