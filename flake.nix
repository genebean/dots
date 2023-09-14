{
  description = "A flake for all my stuff";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs";

    # Controls system level software and settings including fonts
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manages things in home directory
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manage Homebrew itself
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # My oh-my-posh theme
    genebean-omp-themes = {
      url = "github:genebean/my-oh-my-posh-themes";
      flake = false;
    };

  }; # end inputs
  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, genebean-omp-themes, ... }: {
    nixosConfigurations = let
      user = "gene";
    in {
      rainbow-planet = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules/nixos
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user}.imports = [
                ./modules/home-manager
                ./modules/nixos/dconf.nix
              ];
              extraSpecialArgs = { inherit genebean-omp-themes; };
            };
          }
        ];
      }; # end rainbow-planet
    }; # end nixosConfigurations

    # This is only set to work with x86 macOS right now... that will need to be updated
    darwinConfigurations = let
      user = "gene.liverman";
    in {
      Blue-Rock = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        pkgs = import nixpkgs {
          system = "x86_64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # User owning the Homebrew prefix
              user = "${user}";

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }

          ./modules/darwin

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user}.imports = [
                ./modules/home-manager
              ];
              extraSpecialArgs = { inherit genebean-omp-themes; };
            };
          }
        ]; # end modules
      }; # end Blue-Rock
    }; # end darwinConfigurations
  };
}
