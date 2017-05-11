# Includes all the profiles needed for a server.
# One big difference between this and the workstation role is that you generally
# are not standing in front of the system and / or there is no graphical
# interface.
class role::server {
  include ::profile::base
}
