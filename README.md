# Dots

This repo historically contained my dot files and is now transitioning to being a Nix flake that manages my dot files and the things that consume them. Things are changing a lot right now, but historically symlinked files are still in `link/`. Most all the other old stuff is now tucked away under `legacy/` to get it out of the way until I decide what is and isn't needed.

The new Nix bits are driven by `flake.nix` which pulls in things under `modules/`. Initial support is for both x86 macOS and NixOS. New stuff is structured like so, at least for now:

```bash
$ tree . -I legacy* -I link*
.
├── flake.lock
├── flake.nix
├── LICENSE
├── modules
│   ├── darwin
│   │   └── default.nix
│   ├── home-manager
│   │   └── default.nix
│   ├── linux
│   └── nixos
│       ├── dconf.nix
│       ├── default.nix
│       └── hardware-configuration.nix
├── README.md
└── Vagrantfile

6 directories, 10 files
```
