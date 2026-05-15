# terraform-aws-secure-baseline

A small collection of composable AWS Terraform modules where **the hardened
configuration is the default** and insecurity is an explicit, audited opt-out.

**No AWS credentials required.** Every module is validated and tested with a
mocked provider — nothing in this repository deploys infrastructure.

---

## The idea

Most registry modules optimise for a frictionless first `apply`: encryption is
a flag you remember to set, public access is reachable until you lock it down,
logging is off. The safe configuration is *available* but it is not what you
get for free.

This collection inverts that. A module call with only its required inputs
produces a resource that already satisfies the relevant CIS AWS Foundations
Benchmark controls. Turning a control *off* — `block_public_access = false`,
`enforce_tls = false` — is possible, but it is a deliberate line in the diff
that a reviewer will see. Defaults are an attack surface; these defaults are
chosen to be the safe ones.

It is the companion to [iac-security-lab](../iac-security-lab): that project
is the policy-as-code *gate* that rejects misconfigured Terraform. This project
is infrastructure that passes such a gate **by construction**.

---

## Modules

| Module | Status | Summary |
| ------ | ------ | ------- |
| [`s3-bucket`](modules/s3-bucket) | available | Private, encrypted, versioned bucket with a TLS-only policy. |
| [`network`](modules/network) | available | VPC with public/private/intra subnet tiers, flow logs and a locked default SG. |
| `iam-assumable-role` | planned | Assumable role with a permission boundary required by default. |
| `account-baseline` | planned | Composition module — CloudTrail, Config, and password policy, consuming the modules above. |

The collection is designed around three building blocks plus one composition
module that wires them together — the composition is the part that shows
modules are meant to be *combined*, not just called.

---

## Repository layout

```
terraform-aws-secure-baseline/
├── modules/            # the modules themselves — one directory each
│   └── s3-bucket/
│       ├── *.tf            # versions / variables / main / outputs
│       ├── README.md       # hand-written header + injected terraform-docs block
│       └── tests/          # native `terraform test` suites
├── examples/           # one runnable example per module
├── .terraform-docs.yml # doc-generation config, CI-enforced for drift
├── .tflint.hcl         # lint ruleset
├── .pre-commit-config.yaml
└── Makefile            # local interface, mirrors CI
```

---

## Using a module

Reference a module by its subdirectory and a version tag:

```hcl
module "secure_bucket" {
  source = "github.com/R055LE/terraform-aws-secure-baseline//modules/s3-bucket?ref=v0.1.0"

  bucket_name = "my-application-data"
}
```

> **Registry note.** The public Terraform Registry requires one repository per
> module, named `terraform-<provider>-<name>`. This repo is a monorepo so the
> collection reads as one coherent piece; to publish a module to the registry,
> its directory would be split into its own `terraform-aws-<name>` repo. The
> `git::` / `github.com//` source form above works today, unchanged.

---

## Local development

```bash
make check     # fmt-check + validate + test + lint + docs-check — full CI parity
make test      # native terraform test for every module
make docs      # regenerate module READMEs
```

Install the pre-commit hooks once so the same checks run on every commit:

```bash
pre-commit install
```

### Toolchain

| Tool | Purpose |
| ---- | ------- |
| Terraform `>= 1.9` (CI: 1.15.3) | `validate`, native `test` with mocked providers |
| `terraform-docs` 0.24 | module reference tables, CI-checked for drift |
| `tflint` 0.62 | lint, recommended ruleset |
| Trivy | static security scan — hardened defaults must scan clean |
| `pre-commit` | runs fmt / validate / lint / docs before each commit |

Modules pin `terraform >= 1.9.0` and the AWS provider `>= 5.40, < 7.0`.
