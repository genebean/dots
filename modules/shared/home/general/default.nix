{
  config,
  inputs,
  pkgs,
  ...
}:
{
  genebean = {
    programs = {
      atuin-client.enable = true;
      bat.enable = true;
      claude-code.enable = true;
      diff.enable = true;
      git.enable = true;
      nixdiff.enable = true;
      powershell.enable = true;
      sops.enable = true;
      tmux.enable = true;
      vim.enable = true;
    };
    services = {
      tailscale.enable = true;
    };
  };

  home = {
    packages = with pkgs; [
      btop
      bundix
      cargo
      cheat
      deadnix
      # dogdns # seems this is now unmaintained :(
      doggo
      dos2unix
      duf
      dust
      (fastfetch.override { enlightenmentSupport = false; })
      fd
      f2
      glab
      glow
      gomuks
      gotop
      htop
      httpie
      hub
      inputs.nix-auth.packages.${stdenv.hostPlatform.system}.default
      jq
      lazydocker
      lazygit
      lua-language-server
      mcp-nixos
      minicom
      mtr
      nil
      nix-search
      nix-zsh-completions
      nodejs
      nurl
      nvd
      nixfmt-tree
      onefetch
      pre-commit
      puppet-lint
      rename
      ruby
      subversion
      statix
      tldr
      tree
      trippy
      vimv
      watch
      wget
      yq-go
    ];
    sessionVariables = {
      CLICLOLOR = 1;
      PAGER = "less";
    };
  };
  programs = {
    bottom.enable = true;
    broot.enable = true;
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    eza.enable = true;
    fzf.enable = true;
    genebean-neovim.enable = true;
    gh.enable = true;
    irssi.enable = true;
    jq.enable = true;
    nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/repos/dots";
    };
    ripgrep.enable = true;
    zellij = {
      enable = true;
      enableZshIntegration = false;
    };
  }; # end programs
}
