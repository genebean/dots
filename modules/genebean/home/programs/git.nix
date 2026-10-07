{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.git;

  # Nix's own access-tokens config (nix-auth-managed) doesn't get applied to
  # self-hosted git+https flake inputs - only github.com/gitlab.com get that
  # treatment. But Nix's git+https fetcher shells out to the real `git`
  # binary, so a normal host-scoped git credential helper works. Reads the
  # token live from nix-auth's own store at runtime - nothing secret lives
  # in the Nix store, and `nix-auth login`/token rotation stays the single
  # source of truth.
  gitCredentialNixAuth = pkgs.writeShellScriptBin "git-credential-nix-auth" ''
    set -euo pipefail
    [ "''${1:-}" = "get" ] || exit 0
    host=""
    while IFS='=' read -r key value; do
      [ "$key" = "host" ] && host="$value"
    done
    token=$(grep '^access-tokens' "$HOME/.config/nix/access-tokens.conf" \
      | tr ' ' '\n' | grep "^''${host}=" | cut -d= -f2 || true)
    [ -n "$token" ] || exit 0
    echo "username=genebean"
    echo "password=$token"
  '';
in
{
  options.genebean.programs.git = {
    enable = lib.mkEnableOption "Git version control";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      gitCredentialNixAuth
      pkgs.git-filter-repo
    ];

    programs.git = {
      enable = true;
      ignores = [
        "*~"
        "*.swp"
        ".DS_Store"
      ];
      lfs.enable = true;
      package = pkgs.gitFull;
      settings = {
        credential."https://git.home.technicalissues.us".helper =
          "!${gitCredentialNixAuth}/bin/git-credential-nix-auth";

        diff.sopsdiffer.textconv = "sops --config /dev/null --decrypt";

        init = {
          defaultBranch = "main";
        };
        commit = {
          gpgsign = true;
        };
        gpg = {
          format = "ssh";
          ssh = {
            allowedSignersFile = "${config.home.homeDirectory}/.config/git/allowed_signers";
          };
        };
        merge = {
          conflictStyle = "diff3";
          tool = "meld";
        };
        pull = {
          rebase = false;
        };
        user = {
          name = "Gene Liverman";
          signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        };
      };
    };
  };
}
