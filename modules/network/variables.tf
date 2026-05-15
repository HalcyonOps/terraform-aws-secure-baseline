variable "name" {
  description = "Name prefix applied to the VPC and all child resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,40}$", var.name))
    error_message = "name must be 1-40 characters: letters, digits, and hyphens only."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones for the subnets. Subnet CIDRs are placed into these zones in list order."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "At least one availability zone is required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets — routed to an internet gateway. One subnet per entry."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets — outbound via NAT, no inbound route from the internet."
  type        = list(string)
  default     = []
}

variable "intra_subnet_cidrs" {
  description = "CIDR blocks for intra subnets — fully isolated, with no route off the VPC. Intended for databases and internal-only workloads."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign a public IP to instances launched in public subnets. Off by default — attach an explicit EIP or load balancer instead."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Provision NAT gateway(s) so private subnets have outbound internet access."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per availability zone. On by default to keep cost down; set false for AZ-resilient egress, which expects public and private subnet lists of equal length."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS resolution within the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Assign DNS hostnames to instances in the VPC."
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Send VPC flow logs to CloudWatch Logs. On by default — flow logs are a CIS AWS Foundations control (§4)."
  type        = bool
  default     = true
}

variable "flow_log_traffic_type" {
  description = "Which traffic the flow log captures: ALL, ACCEPT, or REJECT."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be one of ALL, ACCEPT, or REJECT."
  }
}

variable "flow_log_retention_days" {
  description = "Retention period, in days, for the flow log CloudWatch log group."
  type        = number
  default     = 90
}

variable "flow_log_kms_key_arn" {
  description = "ARN of a KMS key to encrypt the flow log group. When null, CloudWatch Logs uses AWS-managed encryption."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
