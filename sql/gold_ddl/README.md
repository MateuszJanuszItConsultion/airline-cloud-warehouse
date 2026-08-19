# Gold layer DDL

This folder contains DDL for constraints applied to the Gold layer — primary keys on dimensions and foreign keys on facts.

These are **informational constraints**: Databricks does not enforce them at write time (no rejected inserts on violation), unlike `NOT NULL`, which *is* enforced and is required before a column can become a primary key.

Their purpose is to let BI tools (Power BI, Tableau, and similar) automatically detect table relationships when connecting via JDBC/ODBC, instead of requiring manual join configuration for every report.

**Not auto-applied.** Run manually in Databricks SQL Editor after the Gold tables have been built by `dbt build`. Primary keys must be created before foreign keys that reference them — see the order within [`primary_and_foreign_keys.sql`](primary_and_foreign_keys.sql).

A Terraform-managed version of this infrastructure is planned as a future improvement (see `sql/bronze_ddl/README.md` for the same note on Bronze).