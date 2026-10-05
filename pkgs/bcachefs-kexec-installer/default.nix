# Custom kexec image for nixos-anywhere installs of a bcachefs root.
# bcachefs was removed from mainline (kernel maintainer conflict) and is
# an out-of-tree DKMS-style module again - nixos-anywhere's own default
# kexec image (from nixos-images, github:nix-community/nixos-images#
# kexec-installer-nixos-*) can format a bcachefs filesystem
# (bcachefs-tools is userspace-only) but can't mount one, confirmed via a
# real failed install against tcan-left: `mount: unknown filesystem type
# 'bcachefs'`. This is the exact same kexec-installer nixos-images itself
# builds, with the matching out-of-tree module added.
#
# Referencing config.boot.kernelPackages.bcachefs (rather than a
# hardcoded linuxKernel.packages.linux_X_YY) keeps this self-matching
# whatever kernel the kexec-installer module actually uses - out-of-tree
# modules are ABI-locked to one exact kernel build.
#
# Built via inputs.nixos-images.inputs.nixos-stable.legacyPackages, not
# our own `pkgs.nixos` - nixos-images' own flake.nix builds its kexec
# images the same way (`nixpkgs.legacyPackages.${system}.nixos [...]`,
# where `nixpkgs` is its own nixos-stable/nixos-unstable input), and the
# kexec-installer/noninteractive modules resolve some packages (notably
# the kernel) through that same flake's own input rather than whatever
# pkgs a caller wraps them with. A first attempt using `pkgs.nixos`
# (our own pinned 26.05 pkgs) silently still pulled an unstable kernel
# this way - confirmed via the built image's `uname -r` not matching
# 26.05 at all. Going through nixos-images' own nixos-stable input
# (which we've pointed at our nixpkgs via `.follows` in flake.nix) is
# what actually pins it.
#
# Usage:
#   nix build .#bcachefs-kexec-installer
#   nixos-anywhere --kexec "$(readlink -f result)/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
#     --flake .#<hostname> --extra-files <dir> nixos@<installer-ip>
{ inputs, pkgs }:
(inputs.nixos-images.inputs.nixos-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.nixos [
  inputs.nixos-images.nixosModules.kexec-installer
  inputs.nixos-images.nixosModules.noninteractive
  {
    system.kexec-installer.name = "nixos-kexec-installer-noninteractive";
  }
  (
    { config, ... }:
    {
      boot.extraModulePackages = [ config.boot.kernelPackages.bcachefs ];
      boot.supportedFilesystems = [ "bcachefs" ];
    }
  )
]).config.system.build.kexecInstallerTarball
