{ inputs, ... }: {
  mkDarwinHost = {
    system ? "aarch64-darwin",
    hostname,
    username ? "gene",
    additionalModules ? [],
    additionalSpecialArgs ? {}
  }: inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = { inherit inputs hostname username; } // additionalSpecialArgs;
    modules = [
      ./nixpkgs-settings.nix

      inputs.nix-homebrew.darwinModules.nix-homebrew {
        nix-homebrew = {
          enable = true;        # Install Homebrew under the default prefix
          user = "${username}"; # User owning the Homebrew prefix
          autoMigrate = true;   # Automatically migrate existing Homebrew installations
        };
      }

      inputs.home-manager.darwinModules.home-manager {
        home-manager = {
          extraSpecialArgs = { inherit inputs username; };
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username}.imports = [
            inputs.sops-nix.homeManagerModule # user-level secrets management
            ../modules/home-manager/hosts/${hostname}/${username}.nix 
          ];
        };
      }

      ../modules/system/common/all-darwin.nix # system-wide stuff
      ../modules/hosts/darwin/${hostname} # host specific stuff
    ] ++ additionalModules; # end modules
  }; # end darwinSystem
}