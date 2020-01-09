# @summary This plan applies the `role` class
#
# This plan applies the `role` class which will take care of pulling in
# whatever role should be on the node.
#
plan role::apply_local {
  apply_prep('localhost')

  $results = apply('localhost', _catch_errors => true) { include role }

  $results.each |$result| {
    if $result.ok {
      notice($result.report)
    } else {
      notice($result.error.message)
    }
  }
}
