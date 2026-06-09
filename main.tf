#################################################
# STATE CLEANUP - UAT ACCOUNT
#
# This moves the old UAT for_each instance to a
# temporary Terraform address, then removes it from
# Terraform state without destroying the AWS account.
#################################################

moved {
  from = aws_organizations_account.accounts["uat"]
  to   = aws_organizations_account.uat_removed
}

removed {
  from = aws_organizations_account.uat_removed

  lifecycle {
    destroy = false
  }
}
