{ inputs, ... }:
{
  mkNixosHost =
    {
      system ? "x86_64-linux",
      hostname,
      username ? "gene",
      additionalModules ? [ ],
      additionalSpecialArgs ? { },
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs hostname username;
      }
      // additionalSpecialArgs;
      modules = [
        ./nixpkgs-settings.nix

        inputs.disko.nixosModules.disko

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = { inherit inputs hostname username; };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ../modules/shared/home/general
              ../modules/shared/home/linux
              ../modules/hosts/nixos/${hostname}/home-${username}.nix

              inputs.genebean-neovim.homeManagerModules.default
              inputs.private-flake.homeManagerModules.private.git
              (inputs.private-flake.homeManagerModules.private.${hostname} or { })
            ];
          };
        }

        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.private-flake.nixosModules.private.ssh-keys
        inputs.sops-nix.nixosModules.sops # system wide secrets management
        ../modules/hosts/nixos # system-wide stuff
        ../modules/hosts/nixos/${hostname} # host specific stuff
      ]
      ++ additionalModules;
    };
}
