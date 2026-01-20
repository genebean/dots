{ pkgs, ... }: {
  home.packages = with pkgs; [
    esptool
  ];
  programs = {
    git.settings.aliases = {
      kraken = "!gitkraken -p $(cd \"\${1:-.}\" && git rev-parse --show-toplevel)";
    };
  };
}
