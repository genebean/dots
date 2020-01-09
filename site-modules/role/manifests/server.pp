# @summary Pulls in all the profiles needed for a server.
#
# Pulls in all the profiles needed for a server.
# One big difference between this and the workstation role is that you
# generally are not standing in front of the system and / or there is no graphical
# interface.
#
# The intented method of connecting this role to a node is via the `classes`
# array specified in hiera.
#
class role::server {
  include profile::nix
}
