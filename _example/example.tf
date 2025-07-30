provider "aws" {
  region = "us-east-1"
}

locals {
  environment        = "test"
  label_order        = ["name", "environment"]
  availability_zones = ["us-east-1a", "us-east-1b"]
}

module "vpc" {
  source      = "git::https://github.com/Shanav-Technologies/terraform-aws-vpc.git?ref=v1.0.0"
  name        = "vpc"
  environment = local.environment
  label_order = local.label_order
  cidr_block  = "172.16.0.0/16"
}

#tfsec:ignore:aws-ec2-no-excessive-port-access # Ingnored because these are basic examples, it can be changed via varibales as per requirement.
#tfsec:ignore:aws-ec2-no-public-ingress-acl # Ingnored because these are basic examples, it can be changed via varibales as per requirement.
module "subnets" {
  source             = "git::https://github.com/Shanav-Technologies/terraform-aws-subnet.git?ref=v1.0.0"
  name               = "subnet"
  environment        = local.environment
  label_order        = local.label_order
  availability_zones = local.availability_zones
  vpc_id             = module.vpc.id
  cidr_block         = module.vpc.vpc_cidr_block
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

module "efs" {
  source                    = "./.."
  name                      = "efs"
  environment               = "test"
  creation_token            = "changeme"
  availability_zones        = local.availability_zones
  vpc_id                    = module.vpc.id
  subnets                   = module.subnets.public_subnet_id
  security_groups           = [module.vpc.vpc_default_security_group_id]
  efs_backup_policy_enabled = true
  allow_cidr                = [module.vpc.vpc_cidr_block] #vpc_cidr
  replication_enabled       = true
  replication_configuration_destination = {
    region                 = "us-east-1"
    availability_zone_name = ["us-east-1a", "us-east-1b"]
  }
}