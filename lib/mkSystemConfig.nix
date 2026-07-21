{ inputs, ... }:
{
  mkSystemConfig =
    {
      system,
      username ? "gene",
    }:
    inputs.system-manager.lib.makeSystemConfig {
      specialArgs = { inherit system username; };
      modules = [
        { nixpkgs.hostPlatform = system; }
        ../modules/hosts/home-manager-only/system.nix
      ];
    };
}
