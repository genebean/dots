{ username, ... }:
{
  environment.etc."nix/nix.custom.conf".text = ''
    trusted-users = root ${username}
    extra-substituters = https://cache.flox.dev
    extra-substituters = https://cache.numtide.com
    extra-substituters = https://cache.thalheim.io
    extra-substituters = https://cosmic.cachix.org/
    extra-substituters = https://nix-community.cachix.org
    extra-substituters = https://nixos-raspberrypi.cachix.org
    extra-trusted-public-keys = cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=
    extra-trusted-public-keys = cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=
    extra-trusted-public-keys = flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=
    extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
    extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
    extra-trusted-public-keys = nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=
  '';
}
