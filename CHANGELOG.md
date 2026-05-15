# Changelog

All notable changes to this project are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the modules
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) — released
as annotated git tags (`vMAJOR.MINOR.PATCH`).

## [Unreleased]

### Added

- `s3-bucket` module — a private, encrypted, versioned S3 bucket with a
  TLS-only bucket policy. Every control is on by default.
- Authoring toolchain: `terraform-docs` injection, `tflint`, native
  `terraform test`, pre-commit hooks, and a CI pipeline that runs all of them.
