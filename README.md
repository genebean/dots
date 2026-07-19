# Dots

This repo is a Nix flake that manages most of my setup on macOS and fully manages machines I have that run NixOS as their operating system. It also contains as much configruation as I can make work on other Linux distros such as Ubuntu.

- [Flake structure](#flake-structure)
- [Deploying](#deploying)
- [Formatting and CI](#formatting-and-ci)
- [Historical bits](#historical-bits)
- [Host Bootstrapping](#host-bootstrapping)
  - [Replacements](#replacements)
    - [Raspberry Pi kiosks (`kiosk-gene-desk`, and any future host built the same way)](#raspberry-pi-kiosks-kiosk-gene-desk-and-any-future-host-built-the-same-way)
  - [Net-new Hosts](#net-new-hosts)
    - [Adding a new macOS host](#adding-a-new-macos-host)
      - [Extras steps not done by Nix and/or Homebrew and/or mas](#extras-steps-not-done-by-nix-andor-homebrew-andor-mas)
        - [Setup sudo via Touch ID](#setup-sudo-via-touch-id)
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
  - `genebeanLib` - shared platform-detection helpers passed to all modules via `extraSpecialArgs`
- `modules/` contains Nix modules organized by type:
  - `modules/genebean/` - reusable, option-driven modules under the `genebean.*` namespace
    - `modules/genebean/home/` - Home Manager modules; exposed as `homeManagerModules.genebean`
    - `modules/genebean/darwin/` - nix-darwin companion modules; exposed as `darwinModules.genebean`
  - `modules/shared/` - shared modules imported by multiple hosts
    - `modules/shared/home/general/` - Home Manager config for all GUI users
    - `modules/shared/home/linux/` - Home Manager config for Linux-specific apps
    - `modules/shared/nixos/` - NixOS modules (i18n, flatpaks, restic, etc.)
  - `modules/hosts/` - host-specific configurations
    - `modules/hosts/nixos/` - NixOS host configs and hardware configs
    - `modules/hosts/darwin/` - macOS host configs
    - `modules/hosts/home-manager-only/` - Home Manager-only configs

## Deploying

Local changes are applied with the `nixup`/`nixdiff` aliases (see `AGENTS.md`
for the exact commands they wrap). For deploying to a remote host without
SSHing in and running `nixup` by hand, use
[deploy-rs](https://github.com/serokell/deploy-rs):

```bash
nix run .#deploy-rs -- .#<host>                # build, copy, activate, confirm
nix run .#deploy-rs -- .#<host> --dry-activate # preview without switching
```

Every node in `deploy.nodes` (`flake.nix`) builds itself (`remoteBuild =
true`), so this can be run from any machine that can reach the target over
SSH - not just `mightymac`. Hostnames are resolved via Tailscale MagicDNS, so
no domain needs to be configured anywhere in this repo.

deploy-rs's automatic rollback (magic-rollback) is the main reason to use it
over a manual `nixos-rebuild switch --target-host`: if the new generation
breaks SSH connectivity, it rolls back on its own - important for
`kiosk-entryway` and `kiosk-gene-desk`, which have no keyboard normally
attached and would otherwise need a physical visit to recover.

`--skip-checks` is required when deploying from `mightymac` specifically:
deploy-rs's own pre-deploy `nix flake check` tries to build every system's
derivations locally regardless of any node's `remoteBuild` setting, and
mightymac can't build `x86_64-linux` at all (no local builder for it). Run
`nix flake check` separately beforehand instead - it validates the same
things without attempting to build anything locally that can't be.

Scope: all NixOS hosts plus `mightymac`. `AirPuppet`/`Blue-Rock` and
home-manager-only hosts stay on their existing `darwin-rebuild`/`home-manager
switch` workflows.

## Formatting and CI

This repo uses the following tools for code quality:

- **nixfmt** - Formats Nix files. Run `nix fmt .` to format all files.
- **deadnix** - Finds unused code in Nix files.
- **statix** - Checks Nix code for common issues and style problems.

Pre-commit hooks are configured in `.pre-commit-config.yaml` and run automatically before commits. 
Run `pre-commit install` after checkout to make sure it gets used.

CI validation is defined in `.github/workflows/validate.yml` and mirrors what is done by pre-commit.

## Historical bits

This repo historically contained my dot files. Historically symlinked files on Windows are still in `windows/`. Everything else is just in git history now.

## Host Bootstrapping

### Replacements

Sometimes hosts, or their storage, need replacing... sepcially ones that run on SD cards like `kiosk-gene-desk`. When that time comes, here is how to get it back up and running.

#### Raspberry Pi kiosks (`kiosk-gene-desk`, and any future host built the same way)

These hosts use `disko` for partitioning, `impermanence` for a tmpfs root
(wiped every boot, with an explicit persist allowlist), and
`nixos-anywhere` for install - not a flashed system image. `disko` wipes
the target disk from scratch every time, so this is the same process for
a first-time install and a full replacement (dead SD card, etc).

1. **Build the installer image** (on mightymac, or anywhere with the
   flake): `nix build .#rpi4-installer`. This is a generic
   `nixos-raspberrypi` installer image, pre-decompressed so Raspberry Pi
   Imager can flash it directly - it silently corrupts the card if you
   hand it the raw `.img.zst` instead, since Imager doesn't decompress
   zstd itself. `result` is the flashable `.img` file.

2. **Flash it to a USB drive**, not the SD card - Raspberry Pi Imager,
   "Use custom image", pick `result`.

3. **Connect a display and boot the Pi from that USB drive with the SD
   card removed.** Both matter: `nixos-anywhere`/`disko` can't
   repartition a disk the system is currently running from, and a Pi's
   boot order can prefer the SD card over USB if one's already inserted -
   booting from USB with no SD card present avoids that ambiguity
   entirely. A display is required too: the installer sets a random root
   password on boot and prints it on screen along with its IP - read both
   off the display. You'll need the password again for `nixos-anywhere`
   in step 5. Once it's up, insert the SD card - it's just a second,
   currently-empty disk to the running installer at this point, safe to
   insert at any time after boot.

4. **Seed the bootstrap files.** `disko` wipes `/persist` from scratch,
   so the sops age key has to exist on the target *before*
   `nixos-install`'s activation runs, or `sops-install-secrets` fails on
   first boot with no way to recover short of a manual SSH patch. From
   the repo root:

   ```bash
   scripts/prep-install-bootstrap.sh <hostname>
   ```

   This derives the age key from a per-host SSH key already in
   `modules/shared/secrets.yaml`, seeds a clock file so the fresh boot's
   NTP sync starts from a real floor instead of the image build's
   fallback date (no RTC on these Pis), and tags the last 5 restic
   snapshots already in the backup repo for that hostname as
   `pre-reinstall`, so they survive the fresh install's own backup
   rotation - this talks to the repo directly (mightymac is already a
   valid recipient for the restic secrets), so it works regardless of
   whether the host being replaced is still reachable. Confirm the
   derived age recipient printed at the end matches the host's entry in
   `.sops.yaml` before continuing.

5. **Install:**

   ```bash
   nixos-anywhere --flake ~/repos/dots#<hostname> \
     --extra-files ./nixos-anywhere-extras-<hostname> root@<installer-ip>
   ```

   It'll prompt for the root password from step 3 to make its initial SSH
   connection, then reboots into the real system when done.

6. **Restore state.** SSH in once it's back up, then:

   ```bash
   sudo kiosk-restic-full-restore          # lists available snapshots
   sudo kiosk-restic-full-restore <id>     # restores from a specific one
   ```

   Use the specific `pre-reinstall`-tagged snapshot ID from step 4, not
   whatever's newest - a boot-triggered catch-up backup on the fresh
   install can capture empty state and become "latest" before you get a
   chance to restore, so the tool never guesses for you. This restores
   Home Assistant's `hass-browser_mod` chromium registration, atuin's
   sync-server login, and the tailscale node identity, and stops/starts
   the affected services itself.

7. Verify: chromium shows the kiosk page (browser_mod registered in Home
   Assistant), `atuin status` shows a recent sync, `tailscale status`
   shows the expected node name (if it comes up suffixed like
   `<hostname>-1`, the old pre-replacement node is probably still listed
   as active in the Tailscale admin console under the plain name - remove
   it there).

### Net-new Hosts

The directions below are all a bit dated and likely incomplete 😔 They will be updated as time make practical.

#### Adding a new macOS host

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

##### Extras steps not done by Nix and/or Homebrew and/or mas

###### Setup sudo via Touch ID

1. run `sudo cp /etc/pam.d/sudo_local{.template,}` - this will generate a popup asking permission
2. run `sudo nvim /etc/pam.d/sudo_local` and uncomment line as directed by top comments
3. save via `!w` which will generate a popup asking permission

###### Atuin

Nix installs and configures Atuin, but you still need to log into the server:

1. run `atuin import auto` to import the shell history from before Atuin was installed and running
2. run `read -s akey` and enter the encryption key
3. run `read -s apass` and enter the user password
4. run `atuin login --key=$akey --password=$apass --username=gene`

###### Mouse support

- [Logitech M720 Triathlon mouse](https://support.logi.com/hc/en-us/articles/360024698414--Downloads-M720-Triathlon-Multi-Device-Mouse)

#### Adding a NixOS host

##### Post-install

1. clone this repo
2. create keys for [SOPS](https://georgheiler.com/post/sops/) via `mkdir -p ~/.config/sops/age && nix run nixpkgs#ssh-to-age -- -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt && nix run nixpkgs#ssh-to-age --  -i ~/.ssh/id_ed25519.pub  > ~/.config/sops/age/pub-keys.txt`
3. copy output of `~/.config/sops/age/pub-keys.txt`
4. add entries to `.sops.yaml`
5. run `sops modules/hosts/nixos/$(hostname)/secrets.yaml`
   - if there is an empty yaml file in where you target you will get an error... just delete it and try again
6. edit `sops modules/hosts/nixos/$(hostname)/default.nix` and add the Tailscale service and the block of config for sops.
   - if there is an empty yaml file in where you target you will need to delete it
