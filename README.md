# Dots

This repo is a Nix flake that manages most of my setup on macOS and fully manages machines I have that run NixOS as their operating system.

## Flake structure

The Nix bits are driven by `flake.nix` which pulls in things under `modules/`. Initial support is for both x86 macOS and NixOS. The flake is structured like so:

- description: a human readable description of this flake
- inputs: all the places things are pulled from
- outputs:
  - all the outputs from the inputs
  - a `let` ... `in` block that contains:
    - `darwinHostConfig` which takes 3 params and pulls in all the things needed to use Nix on a macOS host
    - `nixosHostConfig` which takes 3 params and pulls in all the things needed to configure a NixOS host
  - the body of outputs that contains:
    - `darwinConfigurations` contains an entry for each macOS host set to the results of a call to `darwinHostConfig` with values for each of the required parameters
    - `nixosConfigurations` contains an entry for each nixOS host set to the results of a call to `nixosHostConfig` with values for each of the required parameters

The parameters on `darwinHostConfig` & `nixosHostConfig` are:

- `system:` the system definition to use for nixpkgs
- `hostname:` the hostname of the machine being configured
- `username:` the username being configured on the host (all code currently assumes there is a single human user managed by Nix)

## Repo structure

The Nix stuff is structured like so, at least for now:

```bash
$ tree . -I legacy* -I link* --gitignore --dirsfirst
.
├── modules
│   ├── home-manager
│   │   ├── common
│   │   │   ├── linux-apps
│   │   │   │   ├── tilix.nix
│   │   │   │   ├── waybar.nix
│   │   │   │   └── xfce4-terminal.nix
│   │   │   ├── all-cli.nix
│   │   │   ├── all-darwin.nix
│   │   │   ├── all-gui.nix
│   │   │   └── all-linux.nix
│   │   ├── files
│   │   │   ├── tilix
│   │   │   │   └── Beanbag-Mathias.json
│   │   │   ├── waybar
│   │   │   │   ├── config
│   │   │   │   └── style.css
│   │   │   ├── xfce4
│   │   │   │   └── terminal
│   │   │   │       ├── accels.scm
│   │   │   │       └── terminalrc
│   │   │   └── Microsoft.PowerShell_profile.ps1
│   │   └── hosts
│   │       ├── Blue-Rock
│   │       │   └── gene.liverman.nix
│   │       ├── nixnuc
│   │       │   └── gene.nix
│   │       └── rainbow-planet
│   │           └── gene.nix
│   ├── hosts
│   │   ├── darwin
│   │   │   └── Blue-Rock
│   │   │       └── default.nix
│   │   └── nixos
│   │       ├── nixnuc
│   │       │   ├── default.nix
│   │       │   └── hardware-configuration.nix
│   │       └── rainbow-planet
│   │           ├── default.nix
│   │           └── hardware-configuration.nix
│   └── system
│       └── common
│           ├── linux
│           │   └── internationalisation.nix
│           ├── all-darwin.nix
│           └── all-nixos.nix
├── LICENSE
├── README.md
├── Vagrantfile
├── flake.lock
└── flake.nix

23 directories, 29 files

```

## Historical bits

This repo historically contained my dot files. Historically symlinked files are still in `link/`. Most all the other old stuff is now tucked away under `legacy/` to get it out of the way until I decide what is and isn't needed.
