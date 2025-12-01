{ pkgs, ... }: {
  home.packages = with pkgs; [
    # nothing here right now
  ];
  programs = {
    git.settings.aliases = {
      kraken = "!gitkraken -p $(cd \"\${1:-.}\" && git rev-parse --show-toplevel)";
    };
  };
}
