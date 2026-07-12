{
  config,
  inputs,
  lib,
  pkgs,
  genebeanLib,
  username,
  ...
}@args:
let
  # hostname is only a specialArg on NixOS hosts; system only on HM-only hosts
  hostname = args.hostname or "unknown";
  system = args.system or "unknown";
in
{
  programs = {
    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromJSON (
        builtins.unsafeDiscardStringContext (
          builtins.readFile (inputs.genebean-omp-themes + "/beanbag.omp.json")
        )
      );
    };

    zsh = {
      enable = true;
      dotDir = config.home.homeDirectory;
      enableCompletion = true;
      autosuggestion.enable = true;
      history.save = 1000000;
      history.size = 1000000;

      initContent = lib.mkMerge [
        # ─── common (all platforms) ─────────────────────────────────────────────
        ''
          [ -f ~/.private-env ] && source ~/.private-env || echo '~/.private-env is missing'

          export GPG_TTY=$(tty)

          # gfr = git fetch rebase on default branch
          gfr() {
            local default_branch
            default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

            if [ -z "$default_branch" ]; then
              echo "Error: Default branch not found. Run 'git remote set-head origin -a' first."
              return 1
            fi

            git fetch origin "$default_branch":"$default_branch" && git rebase "$default_branch"
          }

          function nv() {
            # Assumes all configs exist in directories named ~/.config/nvim-*
            local config=$(fd --max-depth 1 --glob 'nvim*' ~/.config | fzf --prompt="Neovim Configs > " --height=~50% --layout=reverse --border --exit-0)

            # If I exit fzf without selecting a config, don't open Neovim
            [[ -z $config ]] && echo "No config selected" && return

            # Open Neovim with the selected config
            NVIM_APPNAME=$(basename $config) nvim $*
          }

          function svndiffless() {
            svn diff "$@" |diff-so-fancy |less -R
          }

          function svndiffless-nows() {
            svn diff -x -w "$@" |diff-so-fancy |less -R
          }

          # unset oh-my-zsh's gk so that gk can refer to the gitkraken-cli
          unalias gk
        ''
        # ─── Darwin ─────────────────────────────────────────────────────────────
        (lib.mkIf genebeanLib.isDarwin ''
          # Add GPG Suite binaries to the path
          export PATH=/usr/local/MacGPG2/bin:$PATH

          function otpon() {
            osascript -e 'tell application "yubiswitch" to KeyOn'
          }
          function otpoff() {
            osascript -e 'tell application "yubiswitch" to KeyOff'
          }

          # Include Puppet's normal bin folder since it is installed via Homebrew
          export PATH=$PATH:/opt/puppetlabs/bin
          export PATH=$PATH:/opt/puppetlabs/puppet/bin

          # Podman installer pkg for the cli places podman here
          export PATH=/opt/podman/bin:$PATH
        '')
      ];

      oh-my-zsh = {
        enable = true;
        plugins = [
          "bundler"
          "gem"
          "git"
          "github"
          "history"
          "kubectl"
          "pip"
          "terraform"
          "vagrant"
          "vscode"
        ]
        # ─── Darwin ─────────────────────────────────────────────────────────
        ++ lib.optionals genebeanLib.isDarwin [ "macos" ];
      };

      shellAliases =
        # ─── common (all platforms) ─────────────────────────────────────────
        {
          bcrr = "bolt command run --run-as root --sudo-password-prompt";
          bcrrs = "bcrr --stream --no-verbose";
          beo = "bundle exec onceover run spec --trace --force";
          biv = "bundle install --path=vendor/bundle";
          bottom = "echo 'To run bottom, the command is btm'";
          ce = "code-exploration";
          dots = "cd ~/repos/dots";
          gbc = ''
            git branch --merged | command grep -vE "^(\*|\s*(main|master|develop|production|qa)\s*$)" | command xargs -n 1 git branch -d
          '';
          gitextract = "git log --pretty=email --patch-with-stat --reverse --full-index --binary --";
          gpge = "gpg2 --encrypt --sign --armor -r ";
          hubpr = "hub pull-request --push --browse";
          nvdots = "NVIM_APPNAME=nvim-dots nvim";
          nve = "nvdots ~/repos/dots/modules/home-manager/files/nvim/lua";
          pssh = "ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o KexAlgorithms=+diffie-hellman-group1-sha1 -i ~/.ssh/id_rsa-acceptance";
          sal = "ssh-add -L";
          sshnull = "ssh -o UserKnownHostsFile=/dev/null";
          sz = "source ~/.zshrc";
          trippy = "echo 'To run trippy, the command is trip'";
          usegpg = "killall ssh-agent; export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) && gpgconf --launch gpg-agent";
          usessh = "gpgconf --kill gpg-agent";
        }
        # ─── Darwin ───────────────────────────────────────────────────────────
        // lib.optionalAttrs genebeanLib.isDarwin {
          currentwifi = "networksetup -getairportnetwork en0 |cut -d ':' -f2- | cut -d ' ' -f2-";
          nixup = "sudo darwin-rebuild switch --flake ~/repos/dots";
          uwgconnect = "networksetup -setairportnetwork en0 SecureWest";
          uwgforget = "networksetup -removepreferredwirelessnetwork en0 SecureWest";
          ykey = "pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L";
        }
        # ─── Linux (all Linux) ────────────────────────────────────────────────
        // lib.optionalAttrs pkgs.stdenv.isLinux {
          pbcopy = "wl-copy";
        }
        # ─── NixOS ────────────────────────────────────────────────────────────
        // lib.optionalAttrs genebeanLib.isNixOS {
          nixboot = "sudo nixos-rebuild boot --flake ~/repos/dots && echo 'Time to reboot!'";
          nixup = "sudo nixos-rebuild switch --flake ~/repos/dots";
          nixroutes = "cd ~/repos/dots && echo '=== Current Routes ===' && ip route show && ip -6 route show && echo '' && echo '=== New Build Routes ===' && nix eval --json '.#nixosConfigurations.${hostname}.config.systemd.network.networks.\"10-wan\".routes'";
          uwgconnect = "nmcli dev wifi connect SecureWest password";
          uwgforget = "nmcli connection delete SecureWest";
          ykey = "sudo systemctl restart pcscd && sudo pkill -9 gpg-agent && source ~/.zshrc; ssh-add -L";
        }
        # ─── HM-only (non-NixOS Linux) ────────────────────────────────────────
        // lib.optionalAttrs genebeanLib.isHMOnly {
          nixup = "home-manager switch --flake ~/repos/dots#${username}-${system}";
        };
    };
  };
}
