# s3-bucket

An S3 bucket that is **private, encrypted, and versioned by default**.

Every security control is on unless a variable is explicitly set to turn it
off. The minimal call — a bucket name and nothing else — produces a bucket
that satisfies the CIS AWS Foundations Benchmark §2.1 controls:

- **ACLs disabled** (`BucketOwnerEnforced` ownership) — removes a whole class
  of public-exposure misconfiguration.
- **Block Public Access** — all four settings applied.
- **Server-side encryption** — SSE-S3 (AES256) by default, or SSE-KMS when a
  key ARN is supplied. Encryption is never off.
- **Versioning** — enabled, protecting against overwrite and deletion.
- **TLS-only bucket policy** — denies any request not made over HTTPS.

Opting out of a control (`block_public_access = false`, `enforce_tls = false`)
is possible but deliberate and visible in the diff — the unsafe path is never
the default.

## Usage

```hcl
module "secure_bucket" {
  source = "github.com/R055LE/terraform-aws-secure-baseline//modules/s3-bucket"

  bucket_name = "my-application-data"

  tags = {
    Project = "example"
  }
}
```

See [`examples/s3-bucket`](../../examples/s3-bucket) for a runnable example.

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9.0 |
| aws | >= 5.40, < 7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| bucket\_name | Name of the S3 bucket. Must be globally unique and DNS-compliant. | `string` | n/a | yes |
| block\_public\_access | Apply all four S3 Block Public Access settings. On by default — setting this false is an explicit, audited opt-out. | `bool` | `true` | no |
| bucket\_key\_enabled | Use an S3 Bucket Key to reduce KMS request costs. Only applies when kms\_key\_arn is set. | `bool` | `true` | no |
| enforce\_kms\_encryption | When kms\_key\_arn is set, also deny PutObject requests that do not use that key. Ignored when kms\_key\_arn is null. | `bool` | `true` | no |
| enforce\_tls | Attach a bucket policy statement denying any request not made over TLS (aws:SecureTransport). | `bool` | `true` | no |
| force\_destroy | Allow Terraform to destroy the bucket even when it still contains objects. Off by default to prevent accidental data loss. | `bool` | `false` | no |
| kms\_key\_arn | ARN of a KMS key for server-side encryption. When null, the bucket uses SSE-S3 (AES256). Encryption is always on; this only selects the key. | `string` | `null` | no |
| lifecycle\_rules | Optional lifecycle rules. Each rule expires noncurrent object versions after the given number of days. | <pre>list(object({<br/>    id                                 = string<br/>    prefix                             = optional(string, "")<br/>    noncurrent_version_expiration_days = number<br/>  }))</pre> | `[]` | no |
| logging | Optional server access logging. Provide the target bucket and an optional key prefix. | <pre>object({<br/>    target_bucket = string<br/>    target_prefix = optional(string, "s3-access-logs/")<br/>  })</pre> | `null` | no |
| tags | Tags applied to the bucket. | `map(string)` | `{}` | no |
| versioning\_enabled | Enable object versioning. On by default — protects against accidental overwrite and deletion. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| bucket\_arn | ARN of the bucket. |
| bucket\_domain\_name | Domain name of the bucket. |
| bucket\_id | Name (ID) of the bucket. |
| bucket\_regional\_domain\_name | Region-specific domain name of the bucket. |
<!-- END_TF_DOCS -->
