terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40, < 7.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# A two-AZ VPC with all three subnet tiers. Flow logs, the locked default
# security group, and the isolated intra tier are all applied by default.
module "network" {
  source = "../../modules/network"

  name               = "r055le-secure-baseline-example"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  intra_subnet_cidrs   = ["10.0.20.0/24", "10.0.21.0/24"]

  tags = {
    Project = "terraform-aws-secure-baseline"
    Example = "network"
  }
}

output "vpc_id" {
  description = "ID of the example VPC."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.network.private_subnet_ids
}
