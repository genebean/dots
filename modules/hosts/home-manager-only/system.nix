{ username, ... }:
{
  environment.etc."nix/nix.custom.conf".text = ''
    trusted-users = root ${username}
  '';
}
