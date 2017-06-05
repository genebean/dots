# Includes all the profiles needed for a workstation
class role::workstation {
  include ::profile::base

  case $facts['kernel'] {
    'Darwin': {
      include ::profile::mac
    }
    default: {
      fail("${facts['kernel']} hasn't been setup in the workstation role yet.")
    }
  } # end of kernel case statement
}
