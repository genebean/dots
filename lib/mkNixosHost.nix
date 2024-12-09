{ inputs, ... }: {
  mkNixosHost = {
    system ? "x86_64-linux",
    hostname,
    username ? "gene",
    additionalModules ? [],
    additionalSpecialArgs ? {}
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs hostname username; } // additionalSpecialArgs;
    modules = [
      ./nixpkgs-settings.nix

      inputs.disko.nixosModules.disko

      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          extraSpecialArgs = { inherit inputs hostname username; };
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username}.imports = [
            ../modules/hosts/common
            ../modules/hosts/common/linux/home.nix
            ../modules/hosts/nixos/${hostname}/home-${username}.nix
          ];
        };
      }

      inputs.nix-flatpak.nixosModules.nix-flatpak

      inputs.sops-nix.nixosModules.sops # system wide secrets management
      ../modules/hosts/nixos # system-wide stuff
      ../modules/hosts/nixos/${hostname} # host specific stuff
    ] ++ additionalModules;
  };
}
