{
  config,
  lib,
  username,
  ...
}:
{
  config =
    lib.mkIf config.home-manager.users.${username}.genebean.programs.ungoogled-chromium.enable
      {
        homebrew.casks = [ "ungoogled-chromium" ];
      };
}
