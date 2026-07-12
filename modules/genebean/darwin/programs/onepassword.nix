{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.onepassword.enable {
    homebrew = {
      casks = [
        "1password"
        "1password-cli"
      ];
      masApps = {
        "1Password for Safari" = 1569813296;
      };
    };
  };
}
