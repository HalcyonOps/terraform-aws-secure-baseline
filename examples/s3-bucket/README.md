# Example — s3-bucket

The minimal invocation of the [`s3-bucket`](../../modules/s3-bucket) module.
A bucket name is the only required input; every security control is applied
by default.

```bash
terraform init
terraform plan
```

This example declares an `aws` provider and would require AWS credentials to
`apply`. It exists to be read and to be plan-validated in CI — no resources
are deployed.
