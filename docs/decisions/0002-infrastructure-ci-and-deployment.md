# ADR 0002: Infrastructure CI and deployment model

## Status
Accepted

## Decision
- Pull requests run `terraform plan` for envs/prod and envs/dev in GitHub
  Actions, authenticated via OIDC with a read-only identity (Reader +
  Storage Blob Data Reader). No Azure secrets in GitHub.
- PR plans run with `-lock=false`: the plan identity must not be able to
  write or delete state.
- Databricks root module and asset bundle get static validation only
  (terraform validate without backend, bundle JSON schema).
- `terraform apply` and `bundle deploy` are run locally by the project owner.

## Consequences
- Plan comments and job logs are public (resource IDs, names). Sensitive
  values are masked; subscription ID is accepted as non-secret.
- Deployed state can diverge from merged code until a local apply is run.
- Changes to management locks require Owner-level permissions and are
  always applied locally.

## Alternatives considered
- CI apply via a `production` environment with required reviewers.
- Databricks plan in CI via a service principal with OAuth M2M
  (workload identity federation needs account-level access).
Both are the target setup for the next project.