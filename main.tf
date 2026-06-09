#################################################
# STATE CLEANUP
#
# Remove old UAT account from Terraform state only.
# This does NOT destroy the AWS account.
#################################################

removed {
  from = aws_organizations_account.accounts["uat"]

  lifecycle {
    destroy = false
  }
}
