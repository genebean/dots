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
        inputs.self.systemManagerModules.genebean
        ../modules/hosts/home-manager-only/system.nix
      ];
    };
}
