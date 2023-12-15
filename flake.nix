{
  description = "A flake for all my stuff";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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

    # Format disks with nix-config
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # My oh-my-posh theme
    genebean-omp-themes = {
      url = "github:genebean/my-oh-my-posh-themes";
      flake = false;
    };

  }; # end inputs
  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nix-darwin, home-manager, nix-homebrew, disko, genebean-omp-themes, ... }: let
    inputs = { inherit disko home-manager nixpkgs nixpkgs-unstable nix-darwin; };

    # creates a macOS system config
    darwinSystem = system: hostName: username: nix-darwin.lib.darwinSystem {
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python-2.7.18.6"
          ];
        };
      };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # User owning the Homebrew prefix
            user = "${username}";

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;
          };
        }

        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ./modules/home-manager
              ./modules/home-manager/darwin.nix
            ];
            extraSpecialArgs = { inherit genebean-omp-themes; };
          };
        }

        ./modules/common/darwin/all-hosts.nix
        ./modules/hosts/darwin/${hostName} # ip address, host specific stuff
      ]; # end modules
    }; # end darwinSystem

    # creates a nixos system config
    nixosSystem = system: hostName: username: nixpkgs.lib.nixosSystem {
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-21.4.4" # Well, this sucks, hopefully a fixed version is available soon...
          ];
        };
      };
      modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ./modules/home-manager
              ./modules/home-manager/nixos.nix
            ];
            extraSpecialArgs = { inherit genebean-omp-themes; };
          };
        }

        ./modules/common/nixos/all-hosts.nix
        ./modules/hosts/nixos/${hostName} # ip address, host specific stuff
      ];
    }; # end nixosSystem

  in {
      darwinConfigurations = {
        Blue-Rock = darwinSystem "x86_64-darwin" "Blue-Rock" "gene.liverman";
      };

      nixosConfigurations = {
        rainbow-planet = nixosSystem "x86_64-linux" "rainbow-planet" "gene";
      };
  };
}
