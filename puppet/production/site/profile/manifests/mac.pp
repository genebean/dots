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
    'kompose',
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

  $homebrew_casks = [
    '1password',
    'adium',
    'android-file-transfer',
    'android-platform-tools',
    'araxis-merge',
    'atom',
    'caffeine',
    'docker',
    'firefox',
    'fliqlo',
    'google-chrome',
    'hipchat',
    'iterm2',
    'slack',
    'sourcetree',
    'visual-studio-code',
  ]

  package { $homebrew_casks:
    ensure   => 'installed',
    provider => 'brewcask',
  }

  $pip_packages = [
    'psutil',
    'powerline-status',
  ]

  package { $pip_packages:
    ensure   => 'latest',
    provider => 'pip',
    require  => Package['python'],
  }


  file { "${homedir}/repos":
    ensure => 'directory',
  }

  vcsrepo { "${homedir}/.vim/bundle/Vundle.vim":
    ensure   => 'latest',
    provider => 'git',
    source   => 'https://github.com/VundleVim/Vundle.vim.git',
  }

  vcsrepo { "${homedir}/repos/powerline-fonts":
    ensure   => 'latest',
    provider => 'git',
    source   => 'https://github.com/powerline/fonts.git',
    require  => File["${homedir}/repos"],
    notify   => Exec['update-fonts'],
  }

  exec { 'update-fonts':
    command     => "${homedir}/repos/powerline-fonts/install.sh",
    cwd         => "${homedir}/repos/powerline-fonts",
    logoutput   => true,
    environment => "HOME=${homedir}",
    refreshonly => true,
  }

  vcsrepo { "${homedir}/.oh-my-zsh":
    ensure   => 'present',
    provider => 'git',
    source   => 'https://github.com/robbyrussell/oh-my-zsh.git',
  }

  vcsrepo { "${homedir}/.oh-my-zsh/custom/themes":
    ensure   => 'latest',
    provider => 'git',
    source   => 'git@github.com:genebean/my-oh-zsh-themes.git',
  }
}
