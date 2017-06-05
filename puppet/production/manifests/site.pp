## site.pp ##

# DEFAULT NODE

# The default node definition matches any node lacking a more specific node
# definition. If there are no other nodes in this file, classes declared here
# will be included in every node's catalog, *in addition* to any classes
# specified in the via an ENC for that node.

node default {
  notify{'This is from the default node.':}
}

node 'dawns-macbook-pro' {
  include ::role::workstation
}
