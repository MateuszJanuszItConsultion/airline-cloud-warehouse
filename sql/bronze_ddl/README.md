# Bronze layer DDL

This folder contains the DDL for the Bronze layer tables — the raw landing zone, populated via `COPY INTO` from the Airflow DAG.

These tables are **not** dbt models (they are not built by `dbt run`/`dbt build`) — they are created manually in Databricks and referenced by dbt via `source()`.

This folder exists purely for documentation and disaster-recovery purposes: if the Databricks workspace needs to be rebuilt, these statements define the exact schema Bronze currently uses.

**Not auto-applied.** Run manually in Databricks SQL Editor if recreating the environment. A Terraform-managed version of this infrastructure is planned as a future improvement.