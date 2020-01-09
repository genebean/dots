# @summary Contains the mac specific configuration
#
# Contains the mac specific configuration. This includes packages pulled in via
# Homebrew.
#
# @param [Stdlib::Unixpath] homedir
#   The fully qualified path to my home directory
#
class profile::mac (
  Stdlib::Unixpath $homedir = lookup('homedir'),
) {
  # $path = '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin'
  # notify{'This is from the mac profile.':}
  # exec { 'install homebrew':
  #   command => '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"',
  #   path    => $path,
  #   creates => '/usr/local/bin/brew',
  # }

  #Package { provider => 'homebrew' }
  $homebrew_packages = [
    'bash-completion',
    'bundler-completion',
    'cmake',
    'coreutils',
    'csshx',
    'docker-completion',
    'elixir',
    'erlang',
    'figlet',
    'git',
    'git-flow',
    'gnu-tar',
    'hub',
    'iftop',
    'jq',
    'kompose',
    'mutt',
    'ncftp',
    'openssh',
    'packer',
    'python',
    'ruby',
    'sl',
    'socat',
    'terraform',
    'tmux',
    'tree',
    'unrar',
    'vagrant-completion',
    'vim',
    'watch',
    'wget',
    'zsh',
    'zsh-completions',
  ]

  package { $homebrew_packages:
    ensure   => 'installed',
    provider => 'brew',
  }

  # $homebrew_casks = [
  #   '1password',
  #   'adium',
  #   'android-file-transfer',
  #   'android-platform-tools',
  #   'araxis-merge',
  #   'atom',
  #   'caffeine',
  #   'docker',
  #   'firefox',
  #   'fliqlo',
  #   'google-chrome',
  #   'hipchat',
  #   'iterm2',
  #   'slack',
  #   'sourcetree',
  #   'visual-studio-code',
  # ]
  #
  # package { $homebrew_casks:
  #   ensure   => 'installed',
  #   provider => 'brewcask',
  # }

  $pip_packages = [
    'psutil',
    'powerline-status',
  ]

  package { $pip_packages:
    ensure   => 'latest',
    provider => 'pip',
    require  => Package['python'],
  }
}
