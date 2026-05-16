# Verifies the secure-by-default posture of the account-baseline module.
# Runs against a mocked AWS provider — no credentials, no real API calls.
# Invoke with: terraform -chdir=modules/account-baseline test

mock_provider "aws" {}

# The minimal call must stand up CloudTrail, Config, and the password policy.
run "secure_defaults" {
  command = plan

  variables {
    name_prefix     = "example"
    log_bucket_name = "example-org-log-archive"
  }

  assert {
    condition     = length(aws_cloudtrail.this) == 1
    error_message = "CloudTrail must be enabled by default."
  }

  assert {
    condition     = aws_cloudtrail.this[0].is_multi_region_trail == true
    error_message = "CloudTrail must be a multi-region trail."
  }

  assert {
    condition     = aws_cloudtrail.this[0].enable_log_file_validation == true
    error_message = "CloudTrail log-file validation must be enabled."
  }

  assert {
    condition     = length(aws_config_configuration_recorder.this) == 1 && length(aws_iam_service_linked_role.config) == 1
    error_message = "AWS Config and its service-linked role must be created by default."
  }

  assert {
    condition     = length(aws_iam_account_password_policy.this) == 1
    error_message = "The account password policy must be managed by default."
  }

  assert {
    condition     = aws_iam_account_password_policy.this[0].minimum_password_length == 14 && aws_iam_account_password_policy.this[0].require_symbols == true
    error_message = "The password policy must enforce a 14-character minimum and require symbols."
  }
}

# Config can be turned off — recorder, delivery channel, and service-linked
# role all disappear together.
run "config_disabled" {
  command = plan

  variables {
    name_prefix     = "example"
    log_bucket_name = "example-org-log-archive"
    enable_config   = false
  }

  assert {
    condition = (
      length(aws_config_configuration_recorder.this) == 0 &&
      length(aws_config_delivery_channel.this) == 0 &&
      length(aws_iam_service_linked_role.config) == 0
    )
    error_message = "Disabling Config must remove all of its resources."
  }
}

run "cloudtrail_disabled" {
  command = plan

  variables {
    name_prefix       = "example"
    log_bucket_name   = "example-org-log-archive"
    enable_cloudtrail = false
  }

  assert {
    condition     = length(aws_cloudtrail.this) == 0
    error_message = "Disabling CloudTrail must remove the trail."
  }
}

# Bringing your own Config role wires it straight through to the recorder.
run "config_with_external_role" {
  command = plan

  variables {
    name_prefix                       = "example"
    log_bucket_name                   = "example-org-log-archive"
    create_config_service_linked_role = false
    config_role_arn                   = "arn:aws:iam::111122223333:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
  }

  assert {
    condition     = aws_config_configuration_recorder.this[0].role_arn == "arn:aws:iam::111122223333:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
    error_message = "An externally supplied Config role ARN must be used by the recorder."
  }

  assert {
    condition     = length(aws_iam_service_linked_role.config) == 0
    error_message = "No service-linked role should be created when one is supplied."
  }
}

# Config without a service-linked role and without a supplied role is invalid.
run "config_without_role_rejected" {
  command = plan

  variables {
    name_prefix                       = "example"
    log_bucket_name                   = "example-org-log-archive"
    create_config_service_linked_role = false
  }

  expect_failures = [var.config_role_arn]
}

run "invalid_log_bucket_name_rejected" {
  command = plan

  variables {
    name_prefix     = "example"
    log_bucket_name = "Invalid_Bucket_Name"
  }

  expect_failures = [var.log_bucket_name]
}
