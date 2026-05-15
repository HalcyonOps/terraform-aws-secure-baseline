# Example — iam-assumable-role

A cross-account deploy role built from the
[`iam-assumable-role`](../../modules/iam-assumable-role) module. A permissions
boundary is required, MFA is enforced on assumption, and the session is capped
at one hour — all by default.

```bash
terraform init
terraform plan
```

This example declares an `aws` provider and would require AWS credentials to
`apply`. It exists to be read and plan-validated in CI — no resources are
deployed.
