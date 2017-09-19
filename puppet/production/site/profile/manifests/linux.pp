# Select a profile based on the OS family
class profile::linux {
  case $facts['os']['family'] {
    'Debian': { include ::profile::linux::debian }
    default:  { fail("${facts['os']['family']} isn't supported yet") }
  }

  exec { 'download hub':
    path    => '/bin:/usr/bin',
    command => "curl -s https://api.github.com/repos/github/hub/releases/latest | grep \"browser_download_url.*linux-amd64\" | cut -d '\"' -f4 | xargs -n 1 curl -L | tar -xzvf - -C /tmp && mv /tmp/hub* /usr/local/hub",
    creates => '/usr/local/hub',
  }

  file {'/usr/local/bin/hub':
    ensure => 'link',
    target => '/usr/local/hub/bin/hub',
  }

}

