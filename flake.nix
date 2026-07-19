{
  description = "A flake for all my stuff";
  # nixos-raspberrypi's own binary cache (pre-built vendor kernel/firmware
  # for kiosk-gene-desk). Only inherited automatically when building *from
  # their flake directly*, not when consumed as an input like here - hence
  # declaring it ourselves. This is a build-time/client-side setting; it
  # does not help kiosk-gene-desk's own future rebuilds once deployed -
  # see its nix.settings.extra-substituters for that.
  nixConfig = {
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cup-collector = {
      url = "github:genebean/cup-collector/v1.1.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linting and formatting
    deadnix = {
      url = "github:astro/deadnix";
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

    genebean-neovim = {
      url = "github:genebean/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # My oh-my-posh theme
    genebean-omp-themes = {
      url = "github:genebean/my-oh-my-posh-themes";
      flake = false;
    };

    hermes-social-summerizer = {
      url = "github:genebean/HermesSocialSummerizer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manages things in home directory
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wipes / to tmpfs on every boot, bind-mounting an explicit allowlist
    # of paths back in from a persistent partition
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Controls system level software and settings including fonts on macOS
    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manage flatpaks
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # unstable branch. Use github:gmodena/nix-flatpak/?ref=<tag> to pin releases.

    # Manage Homebrew itself
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      #inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Raspberry Pi hardware support: vendor kernel/firmware packages and a
    # proper declarative bootloader (boot.loader.raspberry-pi) that keeps
    # /boot/firmware in sync on every switch, instead of the one-shot
    # image population nixpkgs' own sd-image module does. Deliberately
    # not following our nixpkgs - its vendor kernel/firmware overlays are
    # pinned to whatever nixpkgs revision it ships with.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

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
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets managemnt
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linting and formatting
    statix = {
      url = "github:astro/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    viscosity-cli = {
      url = "github:genebean/viscosity-cli/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ytdlfin = {
      url = "github:genebean/ytdlfin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      darwinModules.genebean = ./modules/genebean/darwin;
      homeManagerModules.genebean = ./modules/genebean/home;
      nixosModules.genebean = ./modules/genebean/nixos;

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
          additionalModules = [
            inputs.private-flake.nixosModules.private.kiosk
          ];
        };
        kiosk-gene-desk = localLib.mkNixosHost {
          system = "aarch64-linux";
          hostname = "kiosk-gene-desk";
          additionalModules = [
            inputs.impermanence.nixosModules.impermanence
            inputs.nixos-raspberrypi.lib.inject-overlays
            inputs.nixos-raspberrypi.nixosModules.nixpkgs-rpi
            # Replaces inputs.nixos-hardware.nixosModules.raspberry-pi-4 -
            # nixos-raspberrypi provides the same hardware support plus the
            # declarative boot.loader.raspberry-pi module disko needs.
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
            inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.display-vc4
            inputs.nixos-raspberrypi.nixosModules.trusted-nix-caches
            inputs.private-flake.nixosModules.private.kiosk
          ];
          additionalSpecialArgs = {
            inherit (inputs) nixos-raspberrypi;
          };
        };
        nixnuc = localLib.mkNixosHost {
          hostname = "nixnuc";
          additionalModules = [
            inputs.cup-collector.nixosModules.default
            inputs.hermes-social-summerizer.nixosModules.default
            inputs.private-flake.nixosModules.private.nixnuc
            inputs.ytdlfin.nixosModules.default
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

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./pkgs { inherit inputs pkgs; }
      );
    };
}
