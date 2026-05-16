# Example — account-baseline

An account security baseline built from the
[`account-baseline`](../../modules/account-baseline) module: CloudTrail, AWS
Config, an IAM password policy, and a log-archive bucket composed from the
`s3-bucket` module — all from two required inputs.

```bash
terraform init
terraform plan
```

This example declares an `aws` provider and would require AWS credentials to
`apply`. It exists to be read and plan-validated in CI — no resources are
deployed.
