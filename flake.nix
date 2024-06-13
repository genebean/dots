{
  description = "A flake for all my stuff";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows ="nixpkgs";
    };

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

    # Manages things in home directory
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Controls system level software and settings including fonts on macOS
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manage flatpaks
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # unstable branch. Use github:gmodena/nix-flatpak/?ref=<tag> to pin releases.

    # Manage Homebrew itself
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-terraform = {
      url = "github:stackbuilders/nixpkgs-terraform";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    };

    # Secrets managemnt
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows ="nixpkgs";
    };

  }; # end inputs
  outputs = inputs@{
    self, nixpkgs, nixpkgs-unstable, compose2nix, disko, genebean-omp-themes,
    home-manager, nix-darwin, nix-flatpak, nix-homebrew, nixos-hardware, nixpkgs-terraform, sops-nix, ... }: let

    # creates a macOS system config
    darwinHostConfig = { system, hostname, username, additionalModules, additionalSpecialArgs }: nix-darwin.lib.darwinSystem {
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "python-2.7.18.7" ];
        };
        overlays = [ nixpkgs-terraform.overlays.default ];
      };
      specialArgs = { inherit inputs hostname username; } // additionalSpecialArgs;
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
            extraSpecialArgs = { inherit genebean-omp-themes username; };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              sops-nix.homeManagerModule # user-level secrets management
              ./modules/home-manager/hosts/${hostname}/${username}.nix 
            ];
          };
        }

        ./modules/system/common/all-darwin.nix # system-wide stuff
        ./modules/hosts/darwin/${hostname} # host specific stuff
      ] ++ additionalModules; # end modules
    }; # end darwinSystem

    # creates a nixos system config
    nixosHostConfig = { system, hostname, username, additionalModules, additionalSpecialArgs }: nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs compose2nix hostname username;
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "electron-21.4.4" ];
          };
          overlays = [ nixpkgs-terraform.overlays.default ];
        };
      } // additionalSpecialArgs;
      modules = [
        disko.nixosModules.disko

        home-manager.nixosModules.home-manager {
          home-manager = {
            extraSpecialArgs = { inherit genebean-omp-themes hostname username; };
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username}.imports = [
              ./modules/home-manager/hosts/${hostname}/${username}.nix
            ];
          };
        }

        nix-flatpak.nixosModules.nix-flatpak

        sops-nix.nixosModules.sops # system wide secrets management
        ./modules/system/common/all-nixos.nix # system-wide stuff
        ./modules/hosts/nixos/${hostname} # host specific stuff
      ] ++ additionalModules;
    }; # end nixosSystem

    linuxHomeConfig = { system, hostname, username, additionalModules, additionalSpecialArgs }: home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = { inherit genebean-omp-themes hostname username;
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "electron-21.4.4" ];
          };
          overlays = [ nixpkgs-terraform.overlays.default ];
        };
      } // additionalSpecialArgs;
      modules = [
        ./modules/home-manager/hosts/${hostname}/${username}.nix
        {
          home = {
            username = "${username}";
            homeDirectory = "/home/${username}";
          };
        }
        sops-nix.homeManagerModules.sops
      ] ++ additionalModules;
    }; # end homeManagerConfiguration

  in {
    # Darwin (macOS) hosts
    darwinConfigurations = {
      AirPuppet = darwinHostConfig {
        system = "x86_64-darwin";
        hostname = "AirPuppet";
        username = "gene";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
      Blue-Rock = darwinHostConfig {
        system = "x86_64-darwin";
        hostname = "Blue-Rock";
        username = "gene.liverman";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
      mightymac = darwinHostConfig {
        system = "aarch64-darwin";
        hostname = "mightymac";
        username = "gene.liverman";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
    }; # end darwinConfigurations

    # NixOS hosts
    nixosConfigurations = {
      # bigboy = nixosHostConfig {
      #   system = "x86_64-linux";
      #   hostname = "bigbox";
      #   username = "gene";
      #   additionalModules = [
      #     nixos-hardware.nixosModules.lenovo-thinkpad-p52
      #   ];
      #   additionalSpecialArgs = {};
      # };
      hetznix01 = nixosHostConfig {
        system = "aarch64-linux";
        hostname = "hetznix01";
        username = "gene";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
      nixnuc = nixosHostConfig {
        system = "x86_64-linux";
        hostname = "nixnuc";
        username = "gene";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
      rainbow-planet = nixosHostConfig {
        system = "x86_64-linux";
        hostname = "rainbow-planet";
        username = "gene";
        additionalModules = [
          nixos-hardware.nixosModules.dell-xps-13-9360
        ];
        additionalSpecialArgs = {};
      };
    }; # end nixosConfigurations

    # Home Manager (only) users
    homeConfigurations = {
      gene = linuxHomeConfig {
        system = "x86_64-linux";
        hostname = "mini-watcher";
        username = "gene";
        additionalModules = [];
        additionalSpecialArgs = {};
      };
    }; # end homeConfigurations
  };
}
