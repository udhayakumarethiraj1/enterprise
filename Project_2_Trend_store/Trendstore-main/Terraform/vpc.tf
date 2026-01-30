provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "ex-${basename(path.cwd)}"
  region = "ap-south-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example = local.name
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 6.2.0" 

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 100)]

  private_subnet_names = [
    "Private Subnet One",
    "Private Subnet Two",
    "Private Subnet Three"
  ]
  # public_subnet_names omitted to show default name generation for all three subnets

  # 🔑 EKS-required subnet tags
  public_subnet_tags = {
    "kubernetes.io/cluster/my-cluster" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/my-cluster" = "shared"
    "kubernetes.io/role/internal-elb"  = "1"
  }

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true
}
