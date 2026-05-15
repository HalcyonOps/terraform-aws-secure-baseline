# Verifies the secure-by-default posture of the s3-bucket module.
# Runs against a mocked AWS provider — no credentials, no real API calls.
# Invoke with: terraform -chdir=modules/s3-bucket test

mock_provider "aws" {}

# The bare-minimum invocation must produce a fully hardened bucket.
run "secure_defaults" {
  command = plan

  variables {
    bucket_name = "example-secure-bucket"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "Public ACLs must be blocked by default."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "Public bucket policies must be restricted by default."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled by default."
  }

  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "ACLs must be disabled (BucketOwnerEnforced) by default."
  }

  # rule and apply_server_side_encryption_by_default are sets, not lists, so
  # they are flattened with for-expressions rather than indexed.
  assert {
    condition = one([
      for r in aws_s3_bucket_server_side_encryption_configuration.this.rule :
      one([for d in r.apply_server_side_encryption_by_default : d.sse_algorithm])
    ]) == "AES256"
    error_message = "Encryption must default to SSE-S3 (AES256) when no KMS key is given."
  }

  assert {
    condition     = length(aws_s3_bucket_policy.this) == 1
    error_message = "A TLS-enforcing bucket policy must be attached by default."
  }
}

# Supplying a KMS key ARN switches encryption to aws:kms without any other
# change to the call site.
run "kms_encryption_selected" {
  command = plan

  variables {
    bucket_name = "example-kms-bucket"
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/abcd-1234-ef56-7890"
  }

  assert {
    condition = one([
      for r in aws_s3_bucket_server_side_encryption_configuration.this.rule :
      one([for d in r.apply_server_side_encryption_by_default : d.sse_algorithm])
    ]) == "aws:kms"
    error_message = "Providing a KMS key ARN must switch encryption to aws:kms."
  }
}

# Invalid bucket names must be rejected by variable validation, not by AWS.
run "invalid_bucket_name_rejected" {
  command = plan

  variables {
    bucket_name = "Invalid_Bucket_Name"
  }

  expect_failures = [
    var.bucket_name,
  ]
}
