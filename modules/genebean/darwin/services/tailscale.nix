{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.services.tailscale.enable {
    homebrew.casks = [ "tailscale-app" ];
  };
}
