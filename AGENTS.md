# AGENTS.md: terraform-aws-secure-baseline

Composable AWS Terraform modules where **the hardened configuration is the
default** and insecurity is an explicit, audited opt-out.

`modules/` holds the modules, `examples/` the usage, and the authoring
toolchain is terraform-docs, native `terraform test`, tflint and semver, driven
from the `Makefile`.

## Nothing here deploys

**No AWS credentials are required and none should ever be needed.** Every module
is validated and tested against a mocked provider. If a change makes a real
`plan` or `apply` necessary to verify it, that is a signal the test is wrong,
not a reason to reach for credentials.

Never add a real account ID, ARN, bucket name or role name to a fixture. Never
add a provider block that would authenticate.

## Secure by default is the whole product

Most registry modules optimise for a frictionless first `apply`: encryption is a
flag you remember, public access is reachable until you lock it down. This
repository takes the opposite position, so:

- **A new variable defaults to the safe value.** If the insecure setting is
  reachable at all, it is a named, documented opt-out with a description saying
  what it gives up.
- **Never widen a default to make an example simpler.** Fix the example.
- A module that cannot be used securely without reading the README has the
  defaults the wrong way round.

## Before opening a PR

```
make docs      # terraform-docs, or the generated tables go stale
make test      # native terraform tests against the mocked provider
make lint      # tflint
make fmt
```

`terraform fmt` before committing. Generated documentation is generated: change
the source, don't hand-edit the table.

## Conventions

- snake_case for resources, variables and outputs.
- Descriptions on every variable and output. They become the docs.
- One resource per logical concern; don't cram unrelated resources into a file.
- Nothing environment-specific hardcoded; it goes through a variable.
- `CHANGELOG.md` and semver are maintained. A behaviour change to a default is
  not a patch release.

## Claude Code specifics

`CLAUDE.md` is a symlink to this file. Codex reads only `AGENTS.md`, Claude Code
reads only `CLAUDE.md`, and neither reads the other's, so one file serves both.
`/init` will try to replace the symlink with a real file.
