# iam-assumable-role — an IAM role with a permissions boundary required by
# default. The trust policy is built from explicit principals only (never a
# wildcard) and requires MFA for IAM-principal trust unless turned off.
#
# The trust policy is assembled as a local object and jsonencode'd rather than
# built with an aws_iam_policy_document data source: the role's trust
# relationship is its core security contract, and this keeps it fully visible
# in a plan diff and directly assertable in `terraform test`.

locals {
  # Account IDs are trusted via their root principal.
  iam_principal_arns = concat(
    var.trusted_role_arns,
    [for account_id in var.trusted_account_ids : "arn:aws:iam::${account_id}:root"],
  )

  # Conditions applied to the IAM-principal trust statement only.
  assume_conditions = merge(
    var.require_mfa ? { Bool = { "aws:MultiFactorAuthPresent" = "true" } } : {},
    var.external_id != null ? { StringEquals = { "sts:ExternalId" = var.external_id } } : {},
  )

  # Statement trusting IAM principals (roles, users, account roots). Condition
  # is omitted entirely when empty — AWS rejects an empty Condition block.
  iam_statement = length(local.iam_principal_arns) > 0 ? merge(
    {
      Sid       = "TrustIamPrincipals"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = local.iam_principal_arns }
    },
    length(local.assume_conditions) > 0 ? { Condition = local.assume_conditions } : {},
  ) : null

  # Statement trusting AWS service principals. MFA conditions do not apply.
  service_statement = length(var.trusted_service_principals) > 0 ? {
    Sid       = "TrustServicePrincipals"
    Effect    = "Allow"
    Action    = "sts:AssumeRole"
    Principal = { Service = var.trusted_service_principals }
  } : null

  trust_policy = {
    Version   = "2012-10-17"
    Statement = [for statement in [local.iam_statement, local.service_statement] : statement if statement != null]
  }
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  assume_role_policy   = jsonencode(local.trust_policy)
  permissions_boundary = var.permissions_boundary
  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}
