# Changelog

All notable changes to this project are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the modules
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) — released
as annotated git tags (`vMAJOR.MINOR.PATCH`).

## [Unreleased]

### Added

- `s3-bucket` module — a private, encrypted, versioned S3 bucket with a
  TLS-only bucket policy. Every control is on by default.
- `network` module — a VPC with public, private, and fully isolated intra
  subnet tiers. Flow logs on and the default security group locked by default.
- `iam-assumable-role` module — an assumable IAM role with a permissions
  boundary required by default, explicit-principal trust, and MFA on assumption.
- `account-baseline` module — the composition module: CloudTrail, AWS Config,
  and an IAM password policy, consuming the `s3-bucket` module for an encrypted
  log archive.
- `s3-bucket` module — `additional_policy_json` input to merge caller-supplied
  policy documents into the bucket policy (used by `account-baseline` to grant
  CloudTrail and Config log-delivery access).
- Authoring toolchain: `terraform-docs` injection, `tflint`, native
  `terraform test`, pre-commit hooks, and a CI pipeline that runs all of them.
