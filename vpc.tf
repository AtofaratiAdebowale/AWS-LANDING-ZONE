#################################################
# DATABASE ACCOUNT PROVIDER
#
# Cheapest option:
# - Private-only VPC
# - No NAT Gateway
# - No Internet Gateway
# - No public subnet
# - No VPC endpoints
#
# IMPORTANT:
# Do not run Terraform with AWS root credentials.
# Use an IAM user, IAM Identity Center profile, or IAM role
# in the management account that can assume this role.
#################################################

provider "aws" {
  alias   = "database"
  region  = "us-east-1"
  profile = "management"

  assume_role {
    role_arn     = "arn:aws:iam::286217082321:role/OrganizationAccountAccessRole"
    session_name = "terraform-database"
  }
}

#################################################
# DATABASE ACCOUNT VPC
#################################################

resource "aws_vpc" "database" {
  provider = aws.database

  cidr_block           = "10.50.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "adiryx-database-vpc"
    ManagedBy = "Terraform"
    Account   = "Database"
    Project   = "Adiryx Landing Zone"
    CostModel = "Cheapest"
  }
}

#################################################
# DATABASE PRIVATE SUBNETS
#
# Subnets themselves do not have hourly charges.
# Keeping these private avoids NAT Gateway cost.
#################################################

resource "aws_subnet" "database_private_a" {
  provider = aws.database

  vpc_id                  = aws_vpc.database.id
  cidr_block              = "10.50.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name      = "adiryx-database-private-us-east-1a"
    ManagedBy = "Terraform"
    Account   = "Database"
    Tier      = "Private"
    CostModel = "Cheapest"
  }
}

resource "aws_subnet" "database_private_b" {
  provider = aws.database

  vpc_id                  = aws_vpc.database.id
  cidr_block              = "10.50.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name      = "adiryx-database-private-us-east-1b"
    ManagedBy = "Terraform"
    Account   = "Database"
    Tier      = "Private"
    CostModel = "Cheapest"
  }
}

#################################################
# DATABASE PRIVATE ROUTE TABLE
#
# No default route to internet.
# Only local VPC routing exists by default.
#################################################

resource "aws_route_table" "database_private" {
  provider = aws.database

  vpc_id = aws_vpc.database.id

  tags = {
    Name      = "adiryx-database-private-rt"
    ManagedBy = "Terraform"
    Account   = "Database"
    Tier      = "Private"
    CostModel = "Cheapest"
  }
}

#################################################
# DATABASE ROUTE TABLE ASSOCIATIONS
#################################################

resource "aws_route_table_association" "database_private_a" {
  provider = aws.database

  subnet_id      = aws_subnet.database_private_a.id
  route_table_id = aws_route_table.database_private.id
}

resource "aws_route_table_association" "database_private_b" {
  provider = aws.database

  subnet_id      = aws_subnet.database_private_b.id
  route_table_id = aws_route_table.database_private.id
}

#################################################
# DATABASE VPC OUTPUTS
#################################################

output "database_vpc" {
  description = "Database account VPC details."

  value = {
    vpc_id     = aws_vpc.database.id
    cidr_block = aws_vpc.database.cidr_block

    private_subnet_ids = [
      aws_subnet.database_private_a.id,
      aws_subnet.database_private_b.id
    ]

    private_route_table_id = aws_route_table.database_private.id

    cost_model = "private_only_no_nat_gateway_no_internet_gateway"
  }
}
