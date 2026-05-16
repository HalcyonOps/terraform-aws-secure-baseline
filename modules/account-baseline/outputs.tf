output "log_bucket_id" {
  description = "Name of the log-archive S3 bucket."
  value       = module.log_archive.bucket_id
}

output "log_bucket_arn" {
  description = "ARN of the log-archive S3 bucket."
  value       = module.log_archive.bucket_arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail, or null when CloudTrail is disabled."
  value       = try(aws_cloudtrail.this[0].arn, null)
}

output "config_recorder_name" {
  description = "Name of the AWS Config configuration recorder, or null when Config is disabled."
  value       = try(aws_config_configuration_recorder.this[0].name, null)
}

output "config_role_arn" {
  description = "ARN of the IAM role used by AWS Config."
  value       = local.config_role_arn
}

output "password_policy_managed" {
  description = "Whether this module manages the account IAM password policy."
  value       = var.manage_password_policy
}
