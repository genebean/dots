{
  substituters = [
    # genebean/dots#677 - self-hosted, private, needs netrc-file auth too
    # (modules/shared/home/general/default.nix), not just this URL+key.
    "https://attic.home.technicalissues.us/genebean"
    "https://cache.numtide.com"
    "https://cache.thalheim.io"
    "https://nix-community.cachix.org"
    "https://nixos-raspberrypi.cachix.org"
  ];
  trustedPublicKeys = [
    "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
    "genebean:bS9FNZbGEXaJzMJzN5eEva28eCKqDlRC61uC8NdWWL4="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
  ];
}
