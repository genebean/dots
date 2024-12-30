{ pkgs, ... }: {
  # Be sure this is added if on NixOS
  # boot.kernelModules = [ "sg" ];

  # Also, get KEYDB.cfg per https://wiki.archlinux.org/title/Blu-ray

  environment.systemPackages = with pkgs; [
    abcde
    asunder
    handbrake
    lame
    libaacs
    libbdplus
    libbluray
    libdvdcss
    libdvdnav
    libdvdread
    makemkv
    mkvtoolnix
    mkvtoolnix-cli
  ];
}

