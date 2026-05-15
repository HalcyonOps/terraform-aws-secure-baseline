# Verifies the secure-by-default posture of the iam-assumable-role module.
# Runs against a mocked AWS provider — no credentials, no real API calls.
# Invoke with: terraform -chdir=modules/iam-assumable-role test

mock_provider "aws" {}

# Without a permissions boundary and without the explicit opt-out, the module
# must refuse to plan.
run "boundary_required_by_default" {
  command = plan

  variables {
    name              = "example-role"
    trusted_role_arns = ["arn:aws:iam::111122223333:role/deployer"]
  }

  expect_failures = [var.permissions_boundary]
}

# The minimal valid call: a name, a trusted principal, and a boundary.
run "secure_defaults" {
  command = plan

  variables {
    name                 = "example-role"
    trusted_role_arns    = ["arn:aws:iam::111122223333:role/deployer"]
    permissions_boundary = "arn:aws:iam::111122223333:policy/boundary"
  }

  assert {
    condition     = aws_iam_role.this.permissions_boundary == "arn:aws:iam::111122223333:policy/boundary"
    error_message = "The permissions boundary must be applied to the role."
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == 3600
    error_message = "Max session duration must default to one hour."
  }

  assert {
    condition     = strcontains(aws_iam_role.this.assume_role_policy, "aws:MultiFactorAuthPresent")
    error_message = "MFA must be required for IAM-principal trust by default."
  }
}

# The boundary requirement can be waived, but only deliberately.
run "explicit_boundary_opt_out" {
  command = plan

  variables {
    name                               = "example-role"
    trusted_role_arns                  = ["arn:aws:iam::111122223333:role/deployer"]
    allow_missing_permissions_boundary = true
  }

  assert {
    condition     = aws_iam_role.this.permissions_boundary == null
    error_message = "Opting out must produce a role with no boundary attached."
  }
}

# Service-principal trust must not carry an MFA condition.
run "service_principal_trust" {
  command = plan

  variables {
    name                       = "example-role"
    trusted_service_principals = ["lambda.amazonaws.com"]
    permissions_boundary       = "arn:aws:iam::111122223333:policy/boundary"
  }

  assert {
    condition     = strcontains(aws_iam_role.this.assume_role_policy, "lambda.amazonaws.com")
    error_message = "The service principal must appear in the trust policy."
  }

  assert {
    condition     = !strcontains(aws_iam_role.this.assume_role_policy, "aws:MultiFactorAuthPresent")
    error_message = "An MFA condition must not be attached to service-principal trust."
  }
}

# A role with no trusted principal at all is rejected.
run "no_trusted_principals_rejected" {
  command = plan

  variables {
    name                 = "example-role"
    permissions_boundary = "arn:aws:iam::111122223333:policy/boundary"
  }

  expect_failures = [var.trusted_role_arns]
}

# An external ID, when given, becomes a trust-policy condition.
run "external_id_in_trust_policy" {
  command = plan

  variables {
    name                 = "example-role"
    trusted_account_ids  = ["111122223333"]
    permissions_boundary = "arn:aws:iam::111122223333:policy/boundary"
    external_id          = "abc-external-id"
  }

  assert {
    condition     = strcontains(aws_iam_role.this.assume_role_policy, "abc-external-id")
    error_message = "external_id must appear as a trust-policy condition."
  }
}
