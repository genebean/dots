# Select a profile based on the OS family
class profile::linux {
  $homedir = lookup('homedir')
  $uid = find_owner($homedir)
  $gid = find_group($homedir)
  $user = homedir_to_user($homedir)

  case $facts['os']['family'] {
    'Debian': { include profile::linux::debian }
    'RedHat': { include profile::linux::el }
    default:  { fail("${facts['os']['family']} isn't supported yet") }
  }

  file {
    default:
      ensure => directory,
      owner  => $uid,
      group  => $gid,
    ;
    "${homedir}/.local": ;
    "${homedir}/.local/share": ;
    "${homedir}/.local/share/fonts": ;
    '/usr/local/bin/hub':
      ensure => link,
      target => '/usr/local/hub/bin/hub',
    ;
  }

  exec {
    default:
      logoutput   => true,
      environment => "HOME=${homedir}",
      refreshonly => true,
    ;
    'set-font-ownership':
      path      => '/bin:/usr/bin',
      command   => "chown -R ${uid}:${gid} ${homedir}/.local/share/fonts/*",
      cwd       => $homedir,
      require   => Exec['update-fonts'],
      subscribe => Exec['update-fonts'],
    ;
    'download hub':
      path    => '/bin:/usr/bin',
      command => "curl -s https://api.github.com/repos/github/hub/releases/latest | grep \"browser_download_url.*linux-amd64\" | cut -d '\"' -f4 | xargs -n 1 curl -L | tar -xzvf - -C /tmp && mv /tmp/hub* /usr/local/hub",
      creates => '/usr/local/hub',
      before  => File['/usr/local/bin/hub'],
    ;
  }

}

