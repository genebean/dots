# the base profile should include component modules that will be on all nodes
class profile::base {
  $pip_packages = [
    'psutil',
    'powerline-status',
  ]

  package { $pip_packages:
    ensure   => 'latest',
    provider => 'pip',
  }
}
