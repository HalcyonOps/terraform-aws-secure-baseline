variable "name_prefix" {
  description = "Prefix applied to the CloudTrail trail and Config recorder names."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,40}$", var.name_prefix))
    error_message = "name_prefix must be 1-40 characters: letters, digits, and hyphens only."
  }
}

variable "log_bucket_name" {
  description = "Name of the S3 log-archive bucket that CloudTrail and Config deliver to. Created by this module via the s3-bucket module."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.log_bucket_name))
    error_message = "log_bucket_name must be 3-63 characters, lowercase alphanumeric with hyphens or dots, and start and end with an alphanumeric character."
  }
}

variable "log_bucket_kms_key_arn" {
  description = "ARN of a KMS key for the log-archive bucket. When null, the bucket uses SSE-S3 (AES256)."
  type        = string
  default     = null
}

variable "force_destroy_log_bucket" {
  description = "Allow Terraform to destroy the log-archive bucket even when it still contains objects."
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Provision a multi-region CloudTrail trail with log-file validation."
  type        = bool
  default     = true
}

variable "cloudtrail_kms_key_arn" {
  description = "ARN of a KMS key to encrypt CloudTrail log files. When null, CloudTrail uses SSE-S3."
  type        = string
  default     = null
}

variable "enable_config" {
  description = "Provision an AWS Config recorder and delivery channel."
  type        = bool
  default     = true
}

variable "create_config_service_linked_role" {
  description = "Create the Config service-linked role. Set false when it already exists in the account, and pass config_role_arn instead."
  type        = bool
  default     = true
}

variable "config_role_arn" {
  description = "ARN of an existing IAM role for AWS Config. Required when enable_config is true and create_config_service_linked_role is false."
  type        = string
  default     = null

  validation {
    condition     = var.config_role_arn != null || var.create_config_service_linked_role || !var.enable_config
    error_message = "config_role_arn is required when enable_config is true and create_config_service_linked_role is false."
  }
}

variable "manage_password_policy" {
  description = "Manage the account-wide IAM password policy."
  type        = bool
  default     = true
}

variable "password_minimum_length" {
  description = "Minimum length for IAM user passwords."
  type        = number
  default     = 14

  validation {
    condition     = var.password_minimum_length >= 14 && var.password_minimum_length <= 128
    error_message = "password_minimum_length must be between 14 and 128 — 14 is the CIS AWS Foundations minimum."
  }
}

variable "password_max_age" {
  description = "Maximum age, in days, before an IAM user password must be rotated."
  type        = number
  default     = 90
}

variable "password_reuse_prevention" {
  description = "Number of previous passwords that IAM users are prevented from reusing."
  type        = number
  default     = 24
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
