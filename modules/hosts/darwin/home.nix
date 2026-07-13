{ username, ... }:
{
  sops.age.keyFile = "/Users/${username}/Library/Application Support/sops/age/keys.txt";
}
