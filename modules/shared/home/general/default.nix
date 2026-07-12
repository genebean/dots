{
  config,
  inputs,
  pkgs,
  ...
}:
{
  genebean = {
    programs = {
      claude-code.enable = true;
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
      colordiff
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
    atuin = {
      enable = true;
      settings = {
        ctrl_n_shortcuts = true; # Use Ctrl-0 .. Ctrl-9 instead of Alt-0 .. Alt-9 UI shortcuts
        enter_accept = true; # press tab to edit command before running
        filter_mode_shell_up_key_binding = "host"; # or global, host, directory, etc
        sync_address = "https://atuin.home.technicalissues.us";
        sync_frequency = "15m";

      };
    };
    bat = {
      enable = true;
      config = {
        theme = "Catppuccin-frappe";
      };
      themes = {
        Catppuccin-frappe = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
            hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
          };
          file = "Catppuccin-frappe.tmTheme";
        };
      };
    };
    bottom.enable = true;
    broot.enable = true;
    diff-so-fancy = {
      enable = true;
      enableGitIntegration = true;
    };
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
