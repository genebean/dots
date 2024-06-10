{ ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  local_pkgs = final: _prev: import ../pkgs { pkgs = final; config.allowUnfree = true; };
}