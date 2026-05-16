# account-baseline — the composition module. It wires together a baseline of
# account-wide security controls and, in doing so, consumes the s3-bucket
# module for its log archive. The point is that the modules in this collection
# are meant to be combined, not just called one at a time.
#
#   CloudTrail ─┐
#               ├─► s3-bucket  (log archive, encrypted + private by default)
#   AWS Config ─┘
#   IAM account password policy  (account-wide, standalone)

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  trail_name     = "${var.name_prefix}-trail"
  log_bucket_arn = "arn:${local.partition}:s3:::${var.log_bucket_name}"
  # Region is wildcarded so the SourceArn guard does not need a region lookup.
  trail_arn = "arn:${local.partition}:cloudtrail:*:${local.account_id}:trail/${local.trail_name}"

  # Bucket-policy grants for the log-delivery services. Each is jsonencode'd
  # as its own document and merged by the s3-bucket module — keeping each
  # statement list homogeneous and the documents independently testable.
  cloudtrail_policy_document = var.enable_cloudtrail ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = local.log_bucket_arn
        Condition = { StringEquals = { "aws:SourceArn" = local.trail_arn } }
      },
      {
        Sid       = "CloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${local.log_bucket_arn}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
    ]
  }) : null

  config_policy_document = var.enable_config ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ConfigAclCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = local.log_bucket_arn
      },
      {
        Sid       = "ConfigWrite"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${local.log_bucket_arn}/AWSLogs/${local.account_id}/Config/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      },
    ]
  }) : null

  log_bucket_policy_documents = [
    for document in [local.cloudtrail_policy_document, local.config_policy_document] :
    document if document != null
  ]

  config_role_arn = (
    var.create_config_service_linked_role
    ? try(aws_iam_service_linked_role.config[0].arn, null)
    : var.config_role_arn
  )
}

# --- Log archive (composed from the s3-bucket module) ----------------------

module "log_archive" {
  source = "../s3-bucket"

  bucket_name            = var.log_bucket_name
  kms_key_arn            = var.log_bucket_kms_key_arn
  force_destroy          = var.force_destroy_log_bucket
  additional_policy_json = local.log_bucket_policy_documents

  tags = var.tags
}

# --- CloudTrail ------------------------------------------------------------

resource "aws_cloudtrail" "this" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = local.trail_name
  s3_bucket_name                = module.log_archive.bucket_id
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true
  kms_key_id                    = var.cloudtrail_kms_key_arn

  tags = var.tags

  # The bucket policy granting CloudTrail write access must exist first.
  depends_on = [module.log_archive]
}

# --- AWS Config ------------------------------------------------------------

resource "aws_iam_service_linked_role" "config" {
  count = var.enable_config && var.create_config_service_linked_role ? 1 : 0

  aws_service_name = "config.amazonaws.com"
  tags             = var.tags
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_config ? 1 : 0

  name     = "${var.name_prefix}-recorder"
  role_arn = local.config_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_config ? 1 : 0

  name           = "${var.name_prefix}-delivery"
  s3_bucket_name = module.log_archive.bucket_id

  # A delivery channel cannot be created before the recorder it serves.
  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  # Recording can only be enabled once a delivery channel exists.
  depends_on = [aws_config_delivery_channel.this]
}

# --- IAM account password policy -------------------------------------------

resource "aws_iam_account_password_policy" "this" {
  count = var.manage_password_policy ? 1 : 0

  minimum_password_length        = var.password_minimum_length
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = var.password_max_age
  password_reuse_prevention      = var.password_reuse_prevention
}
