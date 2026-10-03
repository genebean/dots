# The `buzz` CLI - outbound messages from Hermes's Buzz plugin shell out to
# this binary ("JSON in, JSON out"); see modules/hosts/nixos/tcan-left/hermes/.
# Not published as a standalone release anywhere - block/buzz only ships
# Desktop app .debs (confirmed via their GitHub releases: every tag is
# `desktop-vX.Y.Z`, bundling the Electron/Tauri app, not a bare CLI binary).
# Built from source instead, same pin/vendoring approach as
# https://github.com/fosskar/buzz-flake's buzz-sidecars package (credit:
# that flake figured out the correct fetchCargoVendor approach for this
# workspace's Cargo.lock - importCargoLock can't handle it, since it
# carries sqlx-core 0.9.0 twice via a [patch.crates-io] fork pin) - narrowed
# here to build only buzz-cli, not that package's other five sidecar
# binaries this fleet has no use for.
#
# Worth its own flake eventually if more than this one binary from this
# workspace ends up needed fleet-wide - kept as a plain dots package for now.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  pkg-config,
  perl,
  openssl,
  protobuf,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz-cli";
  version = "0.5.26";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    rev = "2b4b138dc5cf2d9cc1a0ceb21d9063ff56fe8bf4";
    hash = "sha256-w/CHknkyFT+iHv4jd5Anv1Q/5kOZ7H1DEKB9dwqQHiE=";
  };

  cargoHash = "sha256-A/lpudjM3ZahSNiWHxW8UKFlBhdBuAEQL87c8Q+C7Q4=";

  nativeBuildInputs = [
    cmake
    pkg-config
    perl
    protobuf
  ];

  buildInputs = [ openssl ];

  # cmake is only used by a dependency's build script, not the workspace
  # itself (plain cargo) - the setup hook must not try to configure the
  # source directly.
  dontUseCmakeConfigure = true;

  cargoBuildFlags = [ "--package=buzz-cli" ];

  # The workspace test suite needs a live Postgres, Redis and S3 - not
  # applicable to this one CLI binary either way.
  doCheck = false;

  meta = {
    description = "Buzz CLI - outbound message client for the Buzz Nostr-based human+agent workspace";
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "buzz";
  };
})
