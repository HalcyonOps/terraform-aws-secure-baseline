# Example — network

A two-AZ VPC with public, private, and intra subnet tiers, built from the
[`network`](../../modules/network) module. Flow logs, the locked default
security group, and the isolated intra tier are applied by default.

```bash
terraform init
terraform plan
```

This example declares an `aws` provider and would require AWS credentials to
`apply`. It exists to be read and plan-validated in CI — no resources are
deployed.
