# @summary A standing for a site.pp
#
# A standing for a site.pp that has been modified to work with Bolt.
# A Hiera lookup is done when this class is applied to a node that will look
# for the `classes` array to determine what role the node should be classified
# with.
#
class role {
  lookup('classes', Array[String], 'unique').include
}
