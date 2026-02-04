include apt

# Manage the OpenVox APT repository and install the openvox-agent package
$os_name = downcase($facts['os']['name'])
apt::source { 'openvox8-release':
  comment  => "OpenVox 8 ${os_name}${facts['os']['release']['major']} Repository",
  location => 'https://apt.voxpupuli.org',
  release  => "${os_name}${facts['os']['release']['major']}",
  repos    => 'openvox8',
  key      => {
    'name'   => 'openvox-keyring.gpg',
    'source' => 'https://apt.voxpupuli.org/openvox-keyring.gpg',
  },
}

package { 'openvox-agent':
  ensure  => latest,
  require => Apt::Source['openvox8-release'],
}

# Manage the Mozilla APT repository and install the firefox deb package
# This is to avoid the snap version that comes by default on Ubuntu
# https://www.omgubuntu.co.uk/2022/04/how-to-install-firefox-deb-apt-ubuntu-22-04
apt::source { 'mozilla':
  comment  => 'Mozilla Team',
  location => 'https://packages.mozilla.org/apt',
  release  => 'mozilla',
  repos    => 'main',
  key      => {
    'name'   => 'packages.mozilla.org.asc',
    'ring'   => '/etc/apt/keyrings/packages.mozilla.org.asc',
    'source' => 'https://packages.mozilla.org/apt/repo-signing-key.gpg',
  },
  include  => {
    'src' => false,
  },
}

exec { 'remove_firefox_snap':
  command => '/usr/bin/snap remove firefox',
  onlyif  => '/usr/bin/snap list | /bin/grep firefox',
  notify  => Exec['remove_stock_firefox_fake_deb'],
}

exec { 'remove_stock_firefox_fake_deb':
  command     => '/usr/bin/apt-get -y remove firefox',
  onlyif      => '/usr/bin/dpkg -l | /bin/grep firefox',
  refreshonly => true,
  before      => Package['firefox'],
}

apt::pin { 'mozilla':
  explanation => 'Prefer the Mozilla APT repository for Firefox',
  packages    => '*',
  origin      => 'packages.mozilla.org',
  priority    => 1000,
  before      => Package['firefox'],
}

apt::pin { 'firefox':
  explanation => "Don't use the Ubuntu repository for Firefox",
  packages    => 'firefox*',
  originator  => 'Ubuntu',
  priority    => -1,
  before      => Package['firefox'],
}

package { 'firefox':
  ensure   => latest,
}

## More stuff to come... 

# package { 'vscode':
#   ensure => installed,
#   source => 'https://vscode.download.prss.microsoft.com/dbazure/download/stable/e3550cfac4b63ca4eafca7b601f0d2885817fd1f/code_1.103.0-1754517494_amd64.deb',
# }
