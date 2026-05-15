# iam-assumable-role

An IAM role that can be assumed by explicit principals, with a **permissions
boundary required by default**.

Most role modules treat the boundary as an optional extra. This one inverts
that: a call with no `permissions_boundary` fails to plan. Waiving it is
possible — `allow_missing_permissions_boundary = true` — but it is a
deliberate, reviewable line in the diff, never a silent omission.

What the minimal call gives you:

- **A permissions boundary** — required, so the role can never exceed it even
  if its attached policies are over-broad.
- **Explicit trust only.** The trust policy is built from the principals you
  name. A wildcard principal (`"*"`) is rejected by variable validation.
- **MFA on assumption.** IAM principals must present MFA to assume the role
  (`require_mfa`, on by default). Service-principal trust is exempt — MFA does
  not apply to it.
- **A one-hour session.** `max_session_duration` defaults to 3600 seconds, not
  the 12-hour maximum.

The trust policy is assembled as a local object and `jsonencode`d rather than
built from an `aws_iam_policy_document` data source — the role's trust
relationship is its core security contract, so it stays fully visible in the
plan diff and directly testable.

## Usage

```hcl
module "deploy_role" {
  source = "github.com/R055LE/terraform-aws-secure-baseline//modules/iam-assumable-role?ref=v0.3.0"

  name                 = "ci-deployer"
  trusted_role_arns    = ["arn:aws:iam::111122223333:role/github-actions"]
  permissions_boundary = "arn:aws:iam::111122223333:policy/ci-boundary"

  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}
```

See [`examples/iam-assumable-role`](../../examples/iam-assumable-role) for a
runnable example.

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
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name | Name of the IAM role. | `string` | n/a | yes |
| allow\_missing\_permissions\_boundary | Explicit opt-out from the required permissions boundary. Leave false unless a boundary genuinely cannot be applied. | `bool` | `false` | no |
| description | Description attached to the IAM role. | `string` | `"Managed by Terraform — terraform-aws-secure-baseline."` | no |
| external\_id | Optional sts:ExternalId condition value for cross-account trust. When set, the assuming principal must present this ID. | `string` | `null` | no |
| inline\_policies | Inline policies to attach, keyed by policy name with a JSON policy document as the value. | `map(string)` | `{}` | no |
| managed\_policy\_arns | ARNs of managed policies to attach to the role. | `list(string)` | `[]` | no |
| max\_session\_duration | Maximum session duration in seconds for the assumed role. Defaults to one hour. | `number` | `3600` | no |
| permissions\_boundary | ARN of the IAM policy used as this role's permissions boundary. Required unless allow\_missing\_permissions\_boundary is set. | `string` | `null` | no |
| require\_mfa | Require multi-factor authentication when an IAM principal assumes this role. On by default; it does not apply to service-principal trust. | `bool` | `true` | no |
| tags | Tags applied to the IAM role. | `map(string)` | `{}` | no |
| trusted\_account\_ids | AWS account IDs whose principals may assume this role, trusted via the account root. | `list(string)` | `[]` | no |
| trusted\_role\_arns | ARNs of IAM roles or users permitted to assume this role. | `list(string)` | `[]` | no |
| trusted\_service\_principals | AWS service principals permitted to assume this role, e.g. lambda.amazonaws.com. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| role\_arn | ARN of the IAM role. |
| role\_id | ID of the IAM role. |
| role\_name | Name of the IAM role. |
| role\_unique\_id | Stable unique ID of the IAM role. |
<!-- END_TF_DOCS -->
