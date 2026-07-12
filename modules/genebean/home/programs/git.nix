{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.genebean.programs.git;
in
{
  options.genebean.programs.git = {
    enable = lib.mkEnableOption "Git version control";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.git-filter-repo ];

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
