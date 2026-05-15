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

# A cross-account deploy role. A permissions boundary is required, MFA is
# enforced on assumption by default, and the session is capped at one hour.
module "deploy_role" {
  source = "../../modules/iam-assumable-role"

  name                 = "r055le-secure-baseline-example"
  trusted_role_arns    = ["arn:aws:iam::111122223333:role/github-actions"]
  permissions_boundary = "arn:aws:iam::111122223333:policy/example-boundary"

  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]

  tags = {
    Project = "terraform-aws-secure-baseline"
    Example = "iam-assumable-role"
  }
}

output "role_arn" {
  description = "ARN of the example role."
  value       = module.deploy_role.role_arn
}
