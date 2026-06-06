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

provider "aws" {
  region = "us-east-1"
}

#################################################
# IMPORT EXISTING AWS ORGANIZATION AND ACCOUNTS
#################################################

import {
  to = aws_organizations_organization.adiryx
  id = "o-5myqq34j5n"
}

import {
  to = aws_organizations_account.test
  id = "295435084681"
}

import {
  to = aws_organizations_account.network
  id = "146727531495"
}

import {
  to = aws_organizations_account.identity
  id = "459524413424"
}

import {
  to = aws_organizations_account.soc_platform
  id = "124074140738"
}

#################################################
# EXISTING AWS ORGANIZATION
#################################################

resource "aws_organizations_organization" "adiryx" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "account.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com"
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

data "aws_organizations_organization" "current" {}

locals {
  root_id               = data.aws_organizations_organization.current.roots[0].id
  management_account_id = "719850720600"
}
