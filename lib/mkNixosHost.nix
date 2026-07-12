{ inputs, ... }:
let
  inherit (import ./default.nix { inherit inputs; }) genebeanLib;
in
{
  mkNixosHost =
    {
      system ? "x86_64-linux",
      hostname,
      username ? "gene",
      additionalHomeModules ? [ ],
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
            extraSpecialArgs = {
              inherit
                inputs
                hostname
                username
                ;
              genebeanLib = genebeanLib // {
                isNixOS = true;
              };
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ../modules/shared/home/general
              ../modules/shared/home/linux
              ../modules/hosts/nixos/${hostname}/home-${username}.nix

              inputs.genebean-neovim.homeManagerModules.default
              inputs.nix-flatpak.homeManagerModules.nix-flatpak
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.private-flake.homeManagerModules.private.git
              (inputs.private-flake.homeManagerModules.private.${hostname} or { })
              inputs.self.homeManagerModules.genebean
            ]
            ++ additionalHomeModules;
          };
        }

        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.private-flake.nixosModules.private.ssh-keys
        inputs.self.nixosModules.genebean
        inputs.sops-nix.nixosModules.sops # system wide secrets management
        ../modules/hosts/nixos # system-wide stuff
        ../modules/hosts/nixos/${hostname} # host specific stuff
      ]
      ++ additionalModules;
    };
}
