{
  config,
  lib,
  username,
  ...
}:
{
  config =
    lib.mkIf config.home-manager.users.${username}.genebean.programs.ghostty.installViaHomebrew
      {
        homebrew.casks = [ "ghostty" ];
      };
}
