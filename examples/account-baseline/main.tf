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

# An account security baseline: CloudTrail, AWS Config, an IAM password
# policy, and a log-archive bucket built from the s3-bucket module — all from
# two required inputs.
module "account_baseline" {
  source = "../../modules/account-baseline"

  name_prefix     = "r055le-secure-baseline"
  log_bucket_name = "r055le-secure-baseline-log-archive"

  tags = {
    Project = "terraform-aws-secure-baseline"
    Example = "account-baseline"
  }
}

output "log_bucket_arn" {
  description = "ARN of the log-archive bucket."
  value       = module.account_baseline.log_bucket_arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = module.account_baseline.cloudtrail_arn
}
