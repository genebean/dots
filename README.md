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

## Adding a new macOS host

1. clone this repo
2. add entry to `flake.nix`
3. add file at `modules/home-manager/hosts/< hostname >/< username >.nix`
4. add file at `modules/hosts/< system >/< hostname >/default.nix`
   - run brew leaves and look for things installed from taps you don't want any more
   - uninstall the program and the tap if not adding it to nix
5. run macOS installer from https://determinate.systems/posts/graphical-nix-installer
6. run `nix run nix-darwin -- check --flake ~/repos/dots`
7. run `sudo mv /etc/shells{,.before-nix-darwin}`
8. run `sudo mv /etc/zshenv{,.before-nix-darwin}`
9. Note that you may also have to move or remove `~/.zshrc`
10. Run `nix run nix-darwin -- switch --flake ~/repos/dots`
    1. first (or several) run(s) through homebrew may well fail due to previously installed casks in `/Applications`. You may have to run brew with `--force` to fix this
    2. you may have to run brew multiple times to fix things
    3. in Settings > Privacy & Security > App Management you will need to allow iTerm
    4. **Note:** ensure `firefox-profile-switcher-connector` is linked:
11. After the nix command finally works, open a new shell and it should have all the nixified settings in it.
12. Go into iTerm2 and use the Hack Nerd Mono font so that the prompt and other things look right. You will likely also want to adjust the size of the font.

Now that that is done, setup Atuin:

```bash
atuin import auto
read -s ak
read -s ap
atuin login --key $ak --password $ap --username gene
```

## Adding a NixOS host

### Post-install

1. clone this repo
2. setup SOPS via `mkdir -p ~/.config/sops/age && nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt && nix run nixpkgs#ssh-to-age --  -i ~/.ssh/id_ed25519.pub  > ~/.config/sops/age/pub-keys.txt`
3. copy output of `~/.config/sops/age/pub-keys.txt`
4. add entries to `.sops.yaml`
5. run `sops modules/hosts/nixos/$(hostname)/secrets.yaml`
  - if there is an empty yaml file in where you target you will get an error... just delete it and try again
6. edit `sops modules/hosts/nixos/$(hostname)/default.nix` and add the tailscale service and the block of config for sops.
  - if there is an empty yaml file in where you target you 
