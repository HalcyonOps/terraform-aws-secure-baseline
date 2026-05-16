# account-baseline

The composition module. It stands up an account-wide security baseline —
CloudTrail, AWS Config, and the IAM password policy — and in doing so
**consumes the [`s3-bucket`](../s3-bucket) module** for its log archive.

This is the module that shows the collection is a *system*. The others are
building blocks; `account-baseline` wires them together:

```
CloudTrail ─┐
            ├─► s3-bucket   (log archive — encrypted, private, versioned)
AWS Config ─┘
IAM account password policy   (account-wide)
```

What the minimal call gives you:

- **A log-archive bucket** built from the `s3-bucket` module — so it inherits
  every secure default that module enforces. The CloudTrail and Config
  delivery grants are passed in through `additional_policy_json`.
- **CloudTrail** — multi-region, with log-file validation on. The bucket-policy
  grant is scoped to the trail's ARN (`aws:SourceArn`), closing the
  confused-deputy gap.
- **AWS Config** — a recorder covering all supported resource types plus global
  resources, with a delivery channel to the log archive. The Config
  service-linked role is created for you.
- **An IAM password policy** — 14-character minimum, all four character
  classes, 90-day rotation, 24-password reuse prevention (CIS AWS Foundations).

Each control can be toggled off (`enable_cloudtrail`, `enable_config`,
`manage_password_policy`) for accounts where it is managed elsewhere.

## Usage

```hcl
module "account_baseline" {
  source = "github.com/R055LE/terraform-aws-secure-baseline//modules/account-baseline?ref=v0.1.0"

  name_prefix     = "acme-prod"
  log_bucket_name = "acme-prod-log-archive"
}
```

See [`examples/account-baseline`](../../examples/account-baseline) for a
runnable example.

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.9.0 |
| aws | >= 5.40, < 7.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| log\_archive | ../s3-bucket | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_account_password_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |
| [aws_iam_service_linked_role.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| log\_bucket\_name | Name of the S3 log-archive bucket that CloudTrail and Config deliver to. Created by this module via the s3-bucket module. | `string` | n/a | yes |
| name\_prefix | Prefix applied to the CloudTrail trail and Config recorder names. | `string` | n/a | yes |
| cloudtrail\_kms\_key\_arn | ARN of a KMS key to encrypt CloudTrail log files. When null, CloudTrail uses SSE-S3. | `string` | `null` | no |
| config\_role\_arn | ARN of an existing IAM role for AWS Config. Required when enable\_config is true and create\_config\_service\_linked\_role is false. | `string` | `null` | no |
| create\_config\_service\_linked\_role | Create the Config service-linked role. Set false when it already exists in the account, and pass config\_role\_arn instead. | `bool` | `true` | no |
| enable\_cloudtrail | Provision a multi-region CloudTrail trail with log-file validation. | `bool` | `true` | no |
| enable\_config | Provision an AWS Config recorder and delivery channel. | `bool` | `true` | no |
| force\_destroy\_log\_bucket | Allow Terraform to destroy the log-archive bucket even when it still contains objects. | `bool` | `false` | no |
| log\_bucket\_kms\_key\_arn | ARN of a KMS key for the log-archive bucket. When null, the bucket uses SSE-S3 (AES256). | `string` | `null` | no |
| manage\_password\_policy | Manage the account-wide IAM password policy. | `bool` | `true` | no |
| password\_max\_age | Maximum age, in days, before an IAM user password must be rotated. | `number` | `90` | no |
| password\_minimum\_length | Minimum length for IAM user passwords. | `number` | `14` | no |
| password\_reuse\_prevention | Number of previous passwords that IAM users are prevented from reusing. | `number` | `24` | no |
| tags | Tags applied to all resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cloudtrail\_arn | ARN of the CloudTrail trail, or null when CloudTrail is disabled. |
| config\_recorder\_name | Name of the AWS Config configuration recorder, or null when Config is disabled. |
| config\_role\_arn | ARN of the IAM role used by AWS Config. |
| log\_bucket\_arn | ARN of the log-archive S3 bucket. |
| log\_bucket\_id | Name of the log-archive S3 bucket. |
| password\_policy\_managed | Whether this module manages the account IAM password policy. |
<!-- END_TF_DOCS -->
