variable "bucket_name" {
  description = "Name of the S3 bucket. Must be globally unique and DNS-compliant."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, lowercase alphanumeric with hyphens or dots, and start and end with an alphanumeric character."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even when it still contains objects. Off by default to prevent accidental data loss."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable object versioning. On by default — protects against accidental overwrite and deletion."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of a KMS key for server-side encryption. When null, the bucket uses SSE-S3 (AES256). Encryption is always on; this only selects the key."
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Use an S3 Bucket Key to reduce KMS request costs. Only applies when kms_key_arn is set."
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Apply all four S3 Block Public Access settings. On by default — setting this false is an explicit, audited opt-out."
  type        = bool
  default     = true
}

variable "enforce_tls" {
  description = "Attach a bucket policy statement denying any request not made over TLS (aws:SecureTransport)."
  type        = bool
  default     = true
}

variable "enforce_kms_encryption" {
  description = "When kms_key_arn is set, also deny PutObject requests that do not use that key. Ignored when kms_key_arn is null."
  type        = bool
  default     = true
}

variable "logging" {
  description = "Optional server access logging. Provide the target bucket and an optional key prefix."
  type = object({
    target_bucket = string
    target_prefix = optional(string, "s3-access-logs/")
  })
  default = null
}

variable "lifecycle_rules" {
  description = "Optional lifecycle rules. Each rule expires noncurrent object versions after the given number of days."
  type = list(object({
    id                                 = string
    prefix                             = optional(string, "")
    noncurrent_version_expiration_days = number
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
  default     = {}
}
