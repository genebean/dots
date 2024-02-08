{ pkgs, ... }: {
  system.stateVersion = 4;

  homebrew = {
    # used to have tap sandreas/tap and program m4b-tool
    casks = [
      "backblaze"
      "calibre"
      "steam"
      "vlc"
    ];
    masApps = {
      "HomeCam" = 1292995895;
    };
  };
}
