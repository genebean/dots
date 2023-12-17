{
  description = "A flake for all my stuff";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Controls system level software and settings including fonts on macOS
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

    # creates a macOS system config
    darwinHostConfig = system: hostname: username: nix-darwin.lib.darwinSystem {
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "python-2.7.18.7" ];
        };
      };
      specialArgs = { inherit inputs username hostname; };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;        # Install Homebrew under the default prefix
            user = "${username}"; # User owning the Homebrew prefix
            autoMigrate = true;   # Automatically migrate existing Homebrew installations
          };
        }

        home-manager.darwinModules.home-manager {
          home-manager = {
            extraSpecialArgs = { inherit genebean-omp-themes; };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ./modules/home-manager/hosts/${hostname}/${username}.nix 
            ];
          };
        }

        ./modules/system/common/all-darwin.nix # system-wide stuff
        ./modules/hosts/darwin/${hostname} # host specific stuff
      ]; # end modules
    }; # end darwinSystem

    # creates a nixos system config
    nixosHostConfig = system: hostname: username: nixpkgs.lib.nixosSystem {
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-21.4.4" ];
        };
      };
      specialArgs = { inherit inputs username hostname; };
      modules = [
        home-manager.nixosModules.home-manager {
          home-manager = {
            extraSpecialArgs = { inherit genebean-omp-themes; };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ./modules/home-manager/hosts/${hostname}/${username}.nix
            ];
          };
        }

        ./modules/system/common/all-nixos.nix # system-wide stuff
        ./modules/hosts/nixos/${hostname} # host specific stuff
      ];
    }; # end nixosSystem

  in {
      darwinConfigurations = {
        Blue-Rock = darwinHostConfig "x86_64-darwin" "Blue-Rock" "gene.liverman";
      };

      nixosConfigurations = {
        nixnuc = nixosHostConfig "x86_64-linux" "nixnuc" "gene";
        rainbow-planet = nixosHostConfig "x86_64-linux" "rainbow-planet" "gene";
      };
  };
}
