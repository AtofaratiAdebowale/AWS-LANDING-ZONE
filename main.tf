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
  organization_id       = data.aws_organizations_organization.current.id
  organization_arn      = data.aws_organizations_organization.current.arn
  management_account_id = data.aws_organizations_organization.current.master_account_id
  root_id               = data.aws_organizations_organization.current.roots[0].id

  #################################################
  # Existing AWS accounts already known
  #################################################

  existing_account_ids = {
    test         = "295435084681"
    network      = "146727531495"
    identity     = "459524413424"
    soc_platform = "124074140738"
  }

  #################################################
  # Account definitions
  #
  # IMPORTANT:
  # - Existing accounts must be imported into state.
  # - New accounts require unique email addresses.
  #################################################

  accounts = {
    log_archive = {
      name      = "adiryx-log-archive"
      email     = "aws-log-archive@adiryx.com"
      parent_ou = "security"
    }

    security_tooling = {
      name      = "adiryx-security-tooling"
      email     = "aws-security-tooling@adiryx.com"
      parent_ou = "security"
    }

    network = {
      name       = "adiryx-network"
      email      = "aws-network@adiryx.com"
      parent_ou  = "infrastructure"
      account_id = local.existing_account_ids.network
    }

    identity = {
      name       = "adiryx-identity"
      email      = "aws-identity@adiryx.com"
      parent_ou  = "infrastructure"
      account_id = local.existing_account_ids.identity
    }

    shared_services = {
      name      = "adiryx-shared-services"
      email     = "aws-shared-services@adiryx.com"
      parent_ou = "infrastructure"
    }

    prod = {
      name      = "adiryx-prod"
      email     = "aws-prod@adiryx.com"
      parent_ou = "production"
    }

    dev = {
      name      = "adiryx-dev"
      email     = "aws-dev@adiryx.com"
      parent_ou = "non_production"
    }

    test = {
      name       = "adiryx-test"
      email      = "aws-test@adiryx.com"
      parent_ou  = "non_production"
      account_id = local.existing_account_ids.test
    }

    uat = {
      name      = "adiryx-uat"
      email     = "aws-uat@adiryx.com"
      parent_ou = "non_production"
    }

    soc_platform = {
      name       = "adiryx-soc-platform"
      email      = "aws-soc-platform@adiryx.com"
      parent_ou  = "non_production"
      account_id = local.existing_account_ids.soc_platform
    }

    sandbox = {
      name      = "adiryx-sandbox"
      email     = "aws-sandbox@adiryx.com"
      parent_ou = "sandbox"
    }
  }
}

#################################################
# ORGANIZATIONAL UNITS
#################################################

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "non_production" {
  name      = "Non-Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "suspended" {
  name      = "Suspended"
  parent_id = local.root_id
}

#################################################
# OU LOOKUP MAP
#################################################

locals {
  ou_ids = {
    security       = aws_organizations_organizational_unit.security.id
    infrastructure = aws_organizations_organizational_unit.infrastructure.id
    workloads      = aws_organizations_organizational_unit.workloads.id
    production     = aws_organizations_organizational_unit.production.id
    non_production = aws_organizations_organizational_unit.non_production.id
    sandbox        = aws_organizations_organizational_unit.sandbox.id
    suspended      = aws_organizations_organizational_unit.suspended.id
  }
}

#################################################
# AWS ORGANIZATION ACCOUNTS
#################################################
/* 
resource "aws_organizations_account" "accounts" {
  for_each = local.accounts

  name      = each.value.name
  email     = each.value.email
  parent_id = local.ou_ids[each.value.parent_ou]

  role_name = "OrganizationAccountAccessRole"

  iam_user_access_to_billing = "DENY"

  close_on_deletion = false

  tags = {
    ManagedBy   = "Terraform"
    Environment = each.value.parent_ou
    Project     = "Adiryx Landing Zone"
  }

  lifecycle {
    prevent_destroy = true
  }
}
*/
#################################################
# OUTPUTS
#################################################

output "organization_id" {
  description = "Existing AWS Organization ID."
  value       = local.organization_id
}

output "organization_arn" {
  description = "Existing AWS Organization ARN."
  value       = local.organization_arn
}

output "root_id" {
  description = "AWS Organizations root ID."
  value       = local.root_id
}

output "management_account_id" {
  description = "AWS Organizations management account ID."
  value       = local.management_account_id
}

output "organizational_units" {
  description = "Created AWS Organizational Units."
  value = {
    security       = aws_organizations_organizational_unit.security.id
    infrastructure = aws_organizations_organizational_unit.infrastructure.id
    workloads      = aws_organizations_organizational_unit.workloads.id
    production     = aws_organizations_organizational_unit.production.id
    non_production = aws_organizations_organizational_unit.non_production.id
    sandbox        = aws_organizations_organizational_unit.sandbox.id
    suspended      = aws_organizations_organizational_unit.suspended.id
  }
}
/*
output "accounts" {
  description = "AWS Organization accounts managed by Terraform."
  value = {
    for key, account in aws_organizations_account.accounts : key => {
      name      = account.name
      id        = account.id
      arn       = account.arn
      email     = account.email
      parent_id = account.parent_id
    }
  }
}
*/
