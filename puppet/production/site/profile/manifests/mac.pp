# this contains the mac specific stuff
class profile::mac {
  # $path = '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin'
  # notify{'This is from the mac profile.':}
  # exec { 'install homebrew':
  #   command => '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"',
  #   path    => $path,
  #   creates => '/usr/local/bin/brew',
  # }

  $homedir = lookup('homedir')

  #Package { provider => 'homebrew' }
  $homebrew_packages = [
    'bash-completion',
    'bundler-completion',
    'cmake',
    'coreutils',
    'docker-completion',
    'elixir',
    'erlang',
    'figlet',
    'git',
    'git-flow',
    'gnu-tar',
    'hub',
    'iftop',
    'mutt',
    'packer',
    'python',
    'ruby',
    'sl',
    'socat',
    'tmux',
    'tree',
    'unrar',
    'vagrant-completion',
    'watch',
    'wget',
    'zsh',
    'zsh-completions',
  ]

  package { $homebrew_packages:
    ensure   => 'installed',
    provider => 'brew',
  }

  vcsrepo { "${homedir}/.vim/bundle/Vundle.vim":
    ensure   => 'present',
    provider => 'git',
  }
}
