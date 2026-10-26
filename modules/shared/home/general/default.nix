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
      mcp-nixos.enable = true;
      nixdiff.enable = true;
      powershell.enable = true;
      sops.enable = true;
      tea.enable = true;
      tmux.enable = true;
      vim.enable = true;
    };
    services = {
      tailscale.enable = true;
    };
  };

  home = {
    packages = with pkgs; [
      awscli2
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
      # Stable has beads (1.0.3), but it's too far behind - meaningful work
      # has landed upstream since stable's version was cut. Pull from
      # unstable (1.3.1 at time of writing) instead.
      (import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; }).beads
      inputs.nix-auth.packages.${stdenv.hostPlatform.system}.default
      jq
      lazydocker
      lazygit
      lua-language-server
      minicom
      mtr
      nak
      nil
      nix-search
      nix-zsh-completions
      # Temporary: CVE-2026-111497 (Brotli decoder OOB write, aka Node2Shell/
      # HTTP2Shell) security pin - nixpkgs' own nodejs_24 is still 24.21.0 on
      # both nixos-26.05 and nixpkgs-unstable; see flake.nix's
      # nixpkgs-brotli-security input for the fix commit and promotion
      # status. Remove once that promotes and plain `nodejs` is patched.
      (import inputs.nixpkgs-brotli-security { inherit (pkgs.stdenv.hostPlatform) system; }).nodejs_24
      nurl
      nvd
      nixfmt-tree
      onefetch
      pre-commit
      puppet-lint
      rename
      ruby
      ruff
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
