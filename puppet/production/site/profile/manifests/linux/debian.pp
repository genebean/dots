# Profile for the Debian family of OS's
class profile::linux::debian {
  $homedir = lookup('homedir')
  $uid = find_owner($homedir)
  $gid = find_group($homedir)

  File {
    owner => $uid,
    group => $gid,
  }

  Vcsrepo {
    user  => $uid,
    owner => $uid,
    group => $gid,
  }

  if $facts['os_release']['ubuntu_codename'] {
    $release = $facts['os_release']['ubuntu_codename']
  }
  elsif $facts['os']['lsb']['distcodename'] {
    $release = $facts['os']['lsb']['distcodename']
  }
  else {
    fail("Can't determine what to use in 'release' for the Docker repo")
  }

  apt::source { 'docker':
    location => 'https://download.docker.com/linux/ubuntu',
    release  => $release,
    repos    => 'stable',
    key      => {
      'id'     => '9DC858229FC7DD38854AE2D88D81803C0EBFCD88',
      'source' => 'https://download.docker.com/linux/ubuntu/gpg',
    },
  }

  $apt_packages = [
    'apt-transport-https',
    'bash-completion',
    'ca-certificates',
    'cmake',
    'coreutils',
    'curl',
    'figlet',
    'git',
    'git-flow',
    'pinentry-gnome3',
    'powerline',
    'python',
    'python-pip',
    'python-psutil',
    'scdaemon',
    'software-properties-common',
    'tmux',
    'tree',
    'yubikey-personalization-gui',
    'zsh',
  ]

  package { $apt_packages:
    ensure  => 'installed',
    require => Apt::Source['docker'],
  }

  exec { 'set-shell-to-zsh':
    path        => '/bin:/usr/bin',
    command     => "chsh -s /usr/bin/zsh `grep '${uid}:${gid}' /etc/passwd |cut -d ':' -f1`",
    cwd         => $homedir,
    logoutput   => true,
    environment => "HOME=${homedir}",
    unless      => "grep '${uid}:${gid}' /etc/passwd | grep '/usr/bin/zsh'",
  }


  $dirs = [
    "${homedir}/.local",
    "${homedir}/.local/share",
    "${homedir}/.local/share/fonts",
    "${homedir}/.vim",
    "${homedir}/.vim/bundle",
    "${homedir}/repos",
  ]

  file { $dirs:
    ensure => 'directory',
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

  vcsrepo { "${homedir}/.vim/bundle/Vundle.vim":
    ensure   => 'latest',
    provider => 'git',
    source   => 'https://github.com/VundleVim/Vundle.vim.git',
    require  => File[$dirs],
  }

  vcsrepo { "${homedir}/repos/powerline-fonts":
    ensure   => 'latest',
    provider => 'git',
    source   => 'https://github.com/powerline/fonts.git',
    require  => File[$dirs],
    notify   => Exec['update-fonts'],
  }

  exec { 'update-fonts':
    command     => "${homedir}/repos/powerline-fonts/install.sh",
    cwd         => "${homedir}/repos/powerline-fonts",
    logoutput   => true,
    environment => "HOME=${homedir}",
    refreshonly => true,
    notify      => Exec['set-font-ownership'],
  }

  exec { 'set-font-ownership':
    path        => '/bin:/usr/bin',
    command     => "chown -R ${uid}:${gid} ${homedir}/.local/share/fonts/*",
    cwd         => $homedir,
    logoutput   => true,
    environment => "HOME=${homedir}",
    require     => Exec['update-fonts'],
    refreshonly => true,
  }
}

