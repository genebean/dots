{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.angry-ip-scanner.enable {
    homebrew.casks = [ "angry-ip-scanner" ];
  };
}
