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

# The minimal call: a name is all that is required. Encryption, versioning,
# Block Public Access, and TLS-only enforcement are all applied by default.
module "secure_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name = "r055le-secure-baseline-example"

  tags = {
    Project = "terraform-aws-secure-baseline"
    Example = "s3-bucket"
  }
}

output "bucket_arn" {
  description = "ARN of the example bucket."
  value       = module.secure_bucket.bucket_arn
}
