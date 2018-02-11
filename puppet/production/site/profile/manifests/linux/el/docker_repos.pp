# These repos are the ones setup by
# https://download.docker.com/linux/centos/docker-ce.repo
class profile::linux::el::docker_repos {
  yumrepo { 'docker-ce-edge':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/$basearch/edge',
    descr    => 'Docker CE Edge - $basearch',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-edge-debuginfo':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/debug-$basearch/edge',
    descr    => 'Docker CE Edge - Debuginfo $basearch',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-edge-source':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/source/edge',
    descr    => 'Docker CE Edge - Sources',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-nightly':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/$basearch/nightly',
    descr    => 'Docker CE Nightly - $basearch',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-nightly-debuginfo':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/debug-$basearch/nightly',
    descr    => 'Docker CE Nightly - Debuginfo $basearch',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-nightly-source':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/source/nightly',
    descr    => 'Docker CE Nightly - Sources',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-stable':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/$basearch/stable',
    descr    => 'Docker CE Stable - $basearch',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-stable-debuginfo':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/debug-$basearch/stable',
    descr    => 'Docker CE Stable - Debuginfo $basearch',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-stable-source':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/source/stable',
    descr    => 'Docker CE Stable - Sources',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-test':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/$basearch/test',
    descr    => 'Docker CE Test - $basearch',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-test-debuginfo':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/debug-$basearch/test',
    descr    => 'Docker CE Test - Debuginfo $basearch',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
  yumrepo { 'docker-ce-test-source':
    ensure   => 'present',
    baseurl  => 'https://download.docker.com/linux/centos/7/source/test',
    descr    => 'Docker CE Test - Sources',
    enabled  => '0',
    gpgcheck => '1',
    gpgkey   => 'https://download.docker.com/linux/centos/gpg',
  }
}

