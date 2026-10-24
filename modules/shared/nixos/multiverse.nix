{ inputs, ... }:
{

  ##########################################################################
  #                                                                        #
  #  nixpkgs-multiverse: pins individual packages to an exact version by  #
  #  resolving against nixpkgs' full history (github:fzakaria/            #
  #  nixpkgs-multiverse), instead of a dedicated flake input per pin (the #
  #  nixpkgs-unstable-php-security pattern in flake.nix). Only enabled    #
  #  here - no pins set yet. Set them per-host via:                       #
  #                                                                        #
  #    multiverse.pins.<attr> = "<exact version>";                        #
  #    ... = config.multiverse.pinned.<attr>;  # wherever the package goes #
  #                                                                        #
  #  Only top-level nixpkgs attributes work (confirmed from the module's   #
  #  own option docs) - no python3Packages.*/nodePackages.* nesting.       #
  #  Confirmed this can't help with the current PHP pin specifically:      #
  #  `mvs query versions php84` doesn't have the php2shell-fixed 8.4.27 -  #
  #  multiverse only indexes versions that have actually shipped on a     #
  #  nixpkgs channel, and that fix is still master-only. It becomes usable #
  #  for a pin like that only once the fix promotes to some channel.      #
  #                                                                        #
  ##########################################################################

  imports = [ inputs.nixpkgs-multiverse.nixosModules.default ];

  multiverse.enable = true;
}
