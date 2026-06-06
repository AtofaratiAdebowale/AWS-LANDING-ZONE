```hcl
terraform {
  required_version = ">= 1.6.0"

  cloud {
    organization = "CGIATO2"

    workspaces {
      name = "AWS-LANDING-ZONE"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#################################################
# AWS PROVIDER
#################################################

provider "aws" {
  region = "us-east-1"
}

#################################################
# EXISTING AWS ORGANIZATION - READ ONLY
#################################################

data "aws_organizations_organization" "current" {}

#################################################
# LANDING ZONE LOCALS
#################################################

locals {
  organization_id       = "o-5myqq34j5n"
  management_account_id = "719850720600"
  root_id               = data.aws_organizations_organization.current.roots[0].id

  existing_accounts = {
    test         = "295435084681"
    network      = "146727531495"
    identity     = "459524413424"
    soc_platform = "124074140738"
  }
}

#################################################
# OUTPUTS
#################################################

output "organization_id" {
  description = "Existing AWS Organization ID."
  value       = data.aws_organizations_organization.current.id
}

output "organization_arn" {
  description = "Existing AWS Organization ARN."
  value       = data.aws_organizations_organization.current.arn
}

output "root_id" {
  description = "AWS Organizations root ID."
  value       = local.root_id
}

output "management_account_id" {
  description = "AWS Organizations management account ID."
  value       = local.management_account_id
}

output "existing_accounts" {
  description = "Known existing AWS account IDs for the landing zone."
  value       = local.existing_accounts
}
```
