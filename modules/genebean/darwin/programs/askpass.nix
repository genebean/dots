{
  config,
  lib,
  username,
  ...
}:
{
  config = lib.mkIf config.home-manager.users.${username}.genebean.programs.askpass.enable {
    homebrew = {
      taps = [ "theseal/ssh-askpass" ];
      brews = [ "ssh-askpass" ];
    };
    nix-homebrew.trust.taps = [ "theseal/ssh-askpass" ];
  };
}
