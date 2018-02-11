# Profile for the Red Hat family of OS's
class profile::linux::el {
  $homedir = lookup('homedir')
  $uid = find_owner($homedir)
  $gid = find_group($homedir)
  $user = homedir_to_user($homedir)

  include ::profile::linux::el::docker_repos
  Yumrepo <| |> -> Package <| |> # lint:ignore:spaceship_operator_without_tag

  $yum_packages = [
    'cmake',
    'device-mapper-persistent-data',
    'docker-ce',
    'figlet',
    'git',
    'gitflow',
    'lvm2',
    'python2-pip',
    'python2-psutil',
    'tmux',
    'tree',
    'yum-utils',
    'zsh',
  ]

  $python_pacakges = [
    'powerline-status',
  ]

  package {
    default:
      ensure => 'installed',
    ;
    'epel-release':
      notify => Exec['yum clean all'],
    ;
    $yum_packages:
      require => Package['epel-release'],
    ;
    $python_pacakges:
      ensure   => 'latest',
      provider => 'pip',
      require  => Package['python2-pip'],
    ;
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
    owner  => $uid,
    group  => $gid,
  }

  # Unlike on Mint, powerline is pulled from pip.
  # This makes it so that the line in .tmux.conf works on both.
  file { '/usr/share/powerline':
    ensure  => 'link',
    target  => '/usr/lib/python2.7/site-packages/powerline',
    require => Package[$python_pacakges],
  }

  vcsrepo {
    default:
      ensure   => 'latest',
      user     => $user,
      owner    => $uid,
      group    => $gid,
      provider => 'git',
    ;
    "${homedir}/.oh-my-zsh":
      ensure => 'present',
      source => 'https://github.com/robbyrussell/oh-my-zsh.git',
    ;
    "${homedir}/.oh-my-zsh/custom/themes":
      source => 'git@github.com:genebean/my-oh-zsh-themes.git',
    ;
    "${homedir}/.vim/bundle/Vundle.vim":
      source  => 'https://github.com/VundleVim/Vundle.vim.git',
      require => File[$dirs],
    ;
    "${homedir}/repos/powerline-fonts":
      source  => 'https://github.com/powerline/fonts.git',
      require => File[$dirs],
      notify  => Exec['update-fonts'],
    ;
  }

  exec {
    default:
      logoutput   => true,
      environment => "HOME=${homedir}",
      refreshonly => true,
    ;
    'yum clean all':
      command => '/bin/yum clean all',
    ;
    'set-shell-to-zsh':
      path    => '/bin:/usr/bin',
      command => "chsh -s /usr/bin/zsh `grep '${uid}:${gid}' /etc/passwd |cut -d ':' -f1`",
      cwd     => $homedir,
      unless  => "grep '${uid}:${gid}' /etc/passwd | grep '/usr/bin/zsh'",
      require => Package['zsh'],
    ;
    'update-fonts':
      command => "${homedir}/repos/powerline-fonts/install.sh",
      cwd     => "${homedir}/repos/powerline-fonts",
      notify  => Exec['set-font-ownership'],
    ;
    'set-font-ownership':
      path    => '/bin:/usr/bin',
      command => "chown -R ${uid}:${gid} ${homedir}/.local/share/fonts/*",
      cwd     => $homedir,
      require => Exec['update-fonts'],
    ;
  }
}

