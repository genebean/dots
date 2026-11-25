{
  home.stateVersion = "26.05";

  # pigate is a DMZ bastion: no VPN/mesh overlay, by design - bridging it
  # into the tailnet would defeat the point of segmenting it out. The
  # fleet-wide default (modules/shared/home/general/default.nix) is now
  # lib.mkDefault true, so this plain override is enough, no lib.mkForce
  # needed. genebean.services.dnclient.enable (Nebula) is left unset -
  # its own default is already false.
  genebean.services.tailscale.enable = false;
}
