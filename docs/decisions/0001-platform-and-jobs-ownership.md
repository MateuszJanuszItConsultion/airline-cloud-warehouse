# ADR 0001: Ownership split between Terraform and Databricks Asset Bundles

## Status
Accepted

## Context
The platform (Azure infrastructure, Unity Catalog containers, secrets) and
the workloads running on it (Databricks jobs) change at different pace and
for different reasons. Jobs were previously defined only in the workspace UI,
with code partly in Git and partly only in the workspace.

## Decision
- Terraform owns the platform layer: catalog, schemas, volumes, grants,
  secret scopes and write-only secret values.
- Databricks Asset Bundles own jobs and the code they run from the workspace.
- dbt and ingestion pipelines own tables and data.
- Every object has exactly one owner in code. Jobs are UI_LOCKED.
- Existing jobs were bound (`bundle deployment bind`), not recreated,
  to keep job IDs referenced by Airflow.

## Consequences
- Deploy order on a fresh environment: `terraform apply`, then `bundle deploy`
  (jobs depend on Terraform-managed volumes and secret scopes).
- Platform object names (e.g. secret scope `kafka-aiven`) are a contract
  between both tools; renaming requires changes in both.
- A single identity must deploy the bundle: `root_path` and failure
  notifications resolve to the deploying user.
- Two code-sourcing models coexist (git_source and bundle-synced files);
  the target is one model.