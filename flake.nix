{
  description = "A flake for all my stuff";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Format disks with nix-config
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flox = {
      url = "github:flox/flox/v1.4.4";
    };

    # My oh-my-posh theme
    genebean-omp-themes = {
      url = "github:genebean/my-oh-my-posh-themes";
      flake = false;
    };

    # Manages things in home directory
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Controls system level software and settings including fonts on macOS
    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manage flatpaks
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # unstable branch. Use github:gmodena/nix-flatpak/?ref=<tag> to pin releases.

    # Manage Homebrew itself
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      #inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Private flake for sensitive configs
    private-flake = {
      url = "github:genebean/private-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        simple-nixos-mailserver.follows = "simple-nixos-mailserver";
        sops-nix.follows = "sops-nix";
      };
    };

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets managemnt
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linting and formatting
    deadnix.url = "github:astro/deadnix";
    statix.url = "github:astro/statix";

  }; # end inputs
  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      # Functions that setup systems
      localLib = import ./lib { inherit inputs; };
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # Darwin (macOS) hosts
      darwinConfigurations = {
        AirPuppet = localLib.mkDarwinHost {
          system = "x86_64-darwin";
          hostname = "AirPuppet";
        };
        Blue-Rock = localLib.mkDarwinHost {
          system = "x86_64-darwin";
          hostname = "Blue-Rock";
          username = "gene.liverman";
        };
        mightymac = localLib.mkDarwinHost {
          hostname = "mightymac";
          username = "gene.liverman";
        };
      }; # end darwinConfigurations

      # NixOS hosts
      nixosConfigurations = {
        bigboy = localLib.mkNixosHost {
          hostname = "bigboy";
          additionalModules = [
            inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p52
          ];
        };
        hetznix01 = localLib.mkNixosHost {
          hostname = "hetznix01";
          additionalModules = [
            inputs.private-flake.nixosModules.private.hetznix01
          ];
        };
        hetznix02 = localLib.mkNixosHost {
          system = "aarch64-linux";
          hostname = "hetznix02";
          additionalModules = [
            # inputs.simple-nixos-mailserver.nixosModule
          ];
        };
        kiosk-entryway = localLib.mkNixosHost {
          # Lenovo IdeaCentre Q190
          hostname = "kiosk-entryway";
        };
        kiosk-gene-desk = localLib.mkNixosHost {
          system = "aarch64-linux";
          hostname = "kiosk-gene-desk";
          additionalModules = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
          ];
        };
        nixnas1 = localLib.mkNixosHost {
          hostname = "nixnas1";
          additionalModules = [
            inputs.simple-nixos-mailserver.nixosModule
          ];
        };
        nixnuc = localLib.mkNixosHost {
          hostname = "nixnuc";
          additionalModules = [
            inputs.simple-nixos-mailserver.nixosModule
          ];
        };
        # This machines is currently running Ubuntu and
        # configured with home-manager only.
        #
        #rainbow-planet = localLib.mkNixosHost {
        #  hostname = "rainbow-planet";
        #  additionalModules = [
        #    inputs.nixos-cosmic.nixosModules.default
        #    inputs.nixos-hardware.nixosModules.dell-xps-13-9360
        #  ];
        #};
      }; # end nixosConfigurations

      # Home Manager (only) users
      homeConfigurations = {
        gene-x86_64-linux = localLib.mkHomeConfig {
          homeDirectory = "/home/gene";
          username = "gene";
          system = "x86_64-linux";
        };

        gene-aarch64-linux = localLib.mkHomeConfig {
          homeDirectory = "/home/gene";
          username = "gene";
          system = "aarch64-linux";
        };
      }; # end homeConfigurations

      packages.aarch64-linux.kiosk-gene-desk-sdImage =
        self.nixosConfigurations.kiosk-gene-desk.config.system.build.sdImage;
    };
}
