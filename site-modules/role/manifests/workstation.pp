# @summary Pulls in all the profiles needed for a workstation
#
# Pulls in all the profiles needed for a workstation based on what platform
# is being setup (macOS, Linux, etc.).
#
# The intented method of connecting this role to a node is via the `classes`
# array specified in hiera.
#
class role::workstation {
  case $facts['kernel'] {
    'Darwin': {
      include profile::nix
      include profile::mac
    }
    'Linux': {
      include profile::nix
      include profile::linux
    }
    default: {
      fail("${facts['kernel']} hasn't been setup in the workstation role yet.")
    }
  } # end of kernel case statement
}
