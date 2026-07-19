{
  inputs,
  runCommand,
  zstd,
}:
# Generic RPi4 installer image - bootstrap media for `nixos-anywhere`, not a
# build of any of our own host configs. Decompressed here so it's flashable
# straight from result/, without an extra manual zstd step (and without
# depending on the flashing tool's zstd support).
runCommand "rpi4-installer.img"
  {
    nativeBuildInputs = [ zstd ];
  }
  ''
    img=$(find ${inputs.nixos-raspberrypi.installerImages.rpi4}/sd-image -name '*.img.zst')
    zstd -d "$img" -o $out
  ''
