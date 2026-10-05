# Bootable x86_64 NixOS installer ISO with the bcachefs kernel module
# added - flash this directly to a USB drive instead of the stock
# nixos-minimal ISO when installing a bcachefs root.
#
# Why this exists instead of just using the bcachefs-kexec-installer
# tarball: kexec itself hung twice on real Apple EFI hardware (MacPro6,1)
# during tcan-left's install, well past the ~30s a normal kexec
# transition takes - a known class of issue with some Mac EFI firmware
# and kexec specifically. A real physical boot from USB never had this
# problem (used repeatedly for inspection throughout that same session
# with no issues) - this ISO sidesteps kexec entirely by making the
# bcachefs-capable environment the one you boot into directly.
#
# Usage:
#   nix build .#bcachefs-installer-iso
#   # flash result/iso/*.iso to a USB drive (dd, Etcher, Rufus, etc.),
#   # boot the target from it, then run nixos-anywhere with the kexec
#   # phase skipped, since you're already in a correctly-equipped
#   # environment:
#   nixos-anywhere --phases disko,install,reboot \
#     --flake .#<hostname> --extra-files <dir> --env-password nixos@<installer-ip>
{ inputs, pkgs }:
(inputs.nixos-images.inputs.nixos-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.nixos [
  inputs.nixos-images.nixosModules.image-installer
  (
    { config, ... }:
    {
      boot.extraModulePackages = [ config.boot.kernelPackages.bcachefs ];
      boot.supportedFilesystems = [ "bcachefs" ];
    }
  )
]).config.system.build.isoImage
