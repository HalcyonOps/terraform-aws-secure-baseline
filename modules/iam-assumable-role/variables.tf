variable "name" {
  description = "Name of the IAM role."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]{1,64}$", var.name))
    error_message = "name must be 1-64 characters from the IAM-allowed set: alphanumerics and + = , . @ _ -"
  }
}

variable "description" {
  description = "Description attached to the IAM role."
  type        = string
  default     = "Managed by Terraform — terraform-aws-secure-baseline."
}

variable "trusted_role_arns" {
  description = "ARNs of IAM roles or users permitted to assume this role."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.trusted_role_arns, "*")
    error_message = "trusted_role_arns must list explicit ARNs — a wildcard principal is not allowed."
  }

  validation {
    condition = (
      length(var.trusted_role_arns) +
      length(var.trusted_account_ids) +
      length(var.trusted_service_principals)
    ) > 0
    error_message = "At least one trusted principal is required: set trusted_role_arns, trusted_account_ids, or trusted_service_principals."
  }
}

variable "trusted_account_ids" {
  description = "AWS account IDs whose principals may assume this role, trusted via the account root."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.trusted_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "Each trusted account ID must be exactly 12 digits."
  }
}

variable "trusted_service_principals" {
  description = "AWS service principals permitted to assume this role, e.g. lambda.amazonaws.com."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.trusted_service_principals, "*")
    error_message = "trusted_service_principals must list explicit service names — a wildcard is not allowed."
  }
}

variable "require_mfa" {
  description = "Require multi-factor authentication when an IAM principal assumes this role. On by default; it does not apply to service-principal trust."
  type        = bool
  default     = true
}

variable "external_id" {
  description = "Optional sts:ExternalId condition value for cross-account trust. When set, the assuming principal must present this ID."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the assumed role. Defaults to one hour."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "permissions_boundary" {
  description = "ARN of the IAM policy used as this role's permissions boundary. Required unless allow_missing_permissions_boundary is set."
  type        = string
  default     = null

  validation {
    condition     = var.permissions_boundary != null || var.allow_missing_permissions_boundary
    error_message = "A permissions boundary is required. Set allow_missing_permissions_boundary = true to deliberately and visibly opt out."
  }
}

variable "allow_missing_permissions_boundary" {
  description = "Explicit opt-out from the required permissions boundary. Leave false unless a boundary genuinely cannot be applied."
  type        = bool
  default     = false
}

variable "managed_policy_arns" {
  description = "ARNs of managed policies to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Inline policies to attach, keyed by policy name with a JSON policy document as the value."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the IAM role."
  type        = map(string)
  default     = {}
}
