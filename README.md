# Dots

This repo is a Nix flake that manages most of my setup on macOS and fully manages machines I have that run NixOS as their operating system. It also contains as much configruation as I can make work on other Linux distros such as Ubuntu.

- [Flake structure](#flake-structure)
- [Formatting and CI](#formatting-and-ci)
- [Historical bits](#historical-bits)
- [Adding a new macOS host](#adding-a-new-macos-host)
  - [Extras steps not done by Nix and/or Homebrew and/or mas](#extras-steps-not-done-by-nix-andor-homebrew-andor-mas)
    - [Firefox profile switcher](#firefox-profile-switcher)
    - [Setup sudo via  Touch ID](#setup-sudo-via--touch-id)
    - [Atuin](#atuin)
    - [Mouse support](#mouse-support)
- [Adding a NixOS host](#adding-a-nixos-host)
  - [Post-install](#post-install)

## Flake structure

- `flake.nix` defines inputs, outputs, and instantiates host configurations via `lib/` functions
- `lib/` contains helper functions:
  - `mkNixosHost` - constructs NixOS system configurations
  - `mkDarwinHost` - constructs nix-darwin system configurations
  - `mkHomeConfig` - constructs Home Manager configurations
- `modules/` contains Nix modules organized by type:
  - `modules/shared/` - shared modules imported by multiple hosts
    - `modules/shared/home/general/` - Home Manager config for all GUI users
    - `modules/shared/home/linux/` - Home Manager config for Linux-specific apps
    - `modules/shared/nixos/` - NixOS modules (i18n, flatpaks, restic, etc.)
  - `modules/hosts/` - host-specific configurations
    - `modules/hosts/nixos/` - NixOS host configs and hardware configs
    - `modules/hosts/darwin/` - macOS host configs
    - `modules/hosts/home-manager-only/` - Home Manager-only configs

## Formatting and CI

This repo uses the following tools for code quality:

- **nixfmt** - Formats Nix files. Run `nix fmt .` to format all files.
- **deadnix** - Finds unused code in Nix files.
- **statix** - Checks Nix code for common issues and style problems.

Pre-commit hooks are configured in `.pre-commit-config.yaml` and run automatically before commits. CI validation is defined in `.github/workflows/validate.yml`.

## Historical bits

This repo historically contained my dot files. Historically symlinked files on Windows are still in `windows/`. Everything else is just in git history now.

## Adding a new macOS host

1. run `xcode-select --install` to install the command-line developer tools (this includes the Apple's stock version of Git).
2. create ed25519 ssh key via `ssh-keygen -t ed25519`
3. add key to GitHub account
4. run macOS graphical installer from https://determinate.systems/posts/graphical-nix-installer
5. run `mkdir ~/repos`
6. run `cd ~/repos`
7. run `git clone git@github.com/genebean/dots`
8. create keys for [SOPS](https://georgheiler.com/post/sops/) via `mkdir -p ~/Library/Application\ Support/sops/age && nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/id_ed25519 > ~/Library/Application\ Support/sops/age/keys.txt && nix run nixpkgs#ssh-to-age -- -i ~/.ssh/id_ed25519.pub  >~/Library/Application\ Support/sops/age/pub-keys.txt`
9. run `cat ~/Library/Application\ Support/sops/age/pub-keys.txt |pbcopy`
10. edit `.sops.yaml` and:
    1. paste copied data into a new line under keys
    2. add creation rule
    3. add to common rule
11. run `mkdir modules/home-manager/hosts/$(hostname -s)`
12. run `nix run nixpkgs#sops -- modules/home-manager/hosts/$(hostname -s)/secrets.yaml`
13. Add entries for 
    - `local_git_config` containing something like this:
      ```
      [user]
        email = me@example.com
      ```
    - `local_private_env` containing anything you want exported as env vars or local aliases that you want to keep private
    - `tailscale_key`
14. create `modules/home-manager/hosts/darwin/$(hostname -s)/<username>.nix` based on needs for this machine
15. run `mkdir modules/hosts/darwin/$(hostname -s)`
16. create `modules/hosts/darwin/$(hostname -s)/default.nix` based on need for this machine
17. add entry to `flake.nix`
18. if not a fresh install of macOS,
    - run `brew leaves` and look for things installed from taps you don't want any more
    - uninstall the program and the tap if not adding it to nix
19. run `git add .`
20. run `git status` - it should look something like this:
    ```bash
    gene.liverman@mightymac dots % git status
    On branch main
    Your branch is up to date with 'origin/main'.

    Changes to be committed:
      (use "git restore --staged <file>..." to unstage)
      modified:   .sops.yaml
      modified:   flake.nix
      new file:   modules/home-manager/hosts/mightymac/gene.liverman.nix
      new file:   modules/home-manager/hosts/mightymac/secrets.yaml
      new file:   modules/hosts/darwin/mightymac/default.nix
    ```
21. run `sudo mv /etc/nix/nix.conf{,.before-nix-darwin}`
22. run `sudo mv /etc/zshenv{,.before-nix-darwin}`
23. run `nix run --extra-experimental-features 'nix-command flakes repl-flake' nix-darwin -- check --flake ~/repos/dots`
24. Run `nix run --extra-experimental-features 'nix-command flakes repl-flake'  nix-darwin -- switch --flake ~/repos/dots`
    - if prompted, run `sudo mv /etc/shells{,.before-nix-darwin}`
    - if prompted, run `sudo mv /etc/zshenv{,.before-nix-darwin}`
    - if prompted, you may also have to move or remove `~/.zshrc`
    - on the first (or several) run(s) homebrew may well fail due to previously installed casks or programs in `/Applications`. You may have to run `brew install --force <package name>` to fix this
    - you may have to run brew multiple times to fix things
25. in Settings > Privacy & Security > App Management you will need to allow iTerm
26. After the nix command finally works, open a new iTerm window and it should have all the nixified settings in it.
27. Go into iTerm2's preferences and use the Hack Nerd Mono font so that the prompt and other things look right. You will likely also want to adjust the size of the font.

### Extras steps not done by Nix and/or Homebrew and/or mas

#### Firefox profile switcher

You will need to link `firefox-profile-switcher-connector` for it to work. The easiest way to do this is to run `brew reinstall firefox-profile-switcher-connector` and follow the directions printed in the terminal.

#### Setup sudo via  Touch ID

1. run `sudo cp /etc/pam.d/sudo_local{.template,}` - this will generate a popup asking permission
2. run `sudo nvim /etc/pam.d/sudo_local` and uncomment line as directed by top comments
3. save via `!w` which will generate a popup asking permission

#### Atuin

Nix installs and configures Atuin, but you still need to log into the server:

1. run `atuin import auto` to import the shell history from before Atuin was installed and running
2. run `read -s akey` and enter the encryption key
3. run `read -s apass` and enter the user password
4. run `atuin login --key=$akey --password=$apass --username=gene`

#### Mouse support

- [Logitech M720 Triathlon mouse](https://support.logi.com/hc/en-us/articles/360024698414--Downloads-M720-Triathlon-Multi-Device-Mouse)

## Adding a NixOS host

### Post-install

1. clone this repo
2. create keys for [SOPS](https://georgheiler.com/post/sops/) via `mkdir -p ~/.config/sops/age && nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt && nix run nixpkgs#ssh-to-age --  -i ~/.ssh/id_ed25519.pub  > ~/.config/sops/age/pub-keys.txt`
3. copy output of `~/.config/sops/age/pub-keys.txt`
4. add entries to `.sops.yaml`
5. run `sops modules/hosts/nixos/$(hostname)/secrets.yaml`
   - if there is an empty yaml file in where you target you will get an error... just delete it and try again
6. edit `sops modules/hosts/nixos/$(hostname)/default.nix` and add the Tailscale service and the block of config for sops.
   - if there is an empty yaml file in where you target you will need to delete it
