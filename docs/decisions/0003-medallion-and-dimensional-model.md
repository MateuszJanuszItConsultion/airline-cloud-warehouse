# ADR 0003: Medallion layers with a dimensional model in Gold

## Status
Accepted — recorded retrospectively; decided in the early phase of the project.

## Context
Source data arrives daily from generators and external APIs, sometimes with
records for earlier business dates. Consumers need analysis across domains
(flights, weather, fleet utilization) at a shared grain. Raw data must stay
reproducible for reprocessing and audit.

## Decision
- **Bronze** is append-only: data loaded as received (`COPY INTO`, Auto Loader),
  with technical columns `_ingested_at` and `_source_file`. Bronze DDL is kept
  in `sql/bronze_ddl/`.
- **Silver** cleans and deduplicates with `ROW_NUMBER()` over the business key,
  keeping the latest load. Raw data is never mutated to fix quality issues.
- **Gold** is a star schema: conformed dimensions shared across facts,
  a role-playing dimension (`dim_airport` as origin and destination),
  SCD Type 2 dimensions built with dbt snapshots (aircraft, currency),
  and an accumulating snapshot fact (`fact_flight_lifecycle`).
- Facts load incrementally with `merge`, using `_ingested_at` as the watermark,
  not the business date.
- A custom `generate_schema_name` macro maps layers to literal schema names
  (`bronze`, `silver`, `gold`), independent of the dbt target.

## Alternatives considered
- **Watermark on the business date** — rejected: late-arriving records for
  earlier dates would be skipped silently (see lessons learned, entry 8).
- **Full table rebuilds on every run** — simpler, but hides incremental-logic
  problems that appear in real systems, and scales poorly.
- **Deduplicating in Bronze** — rejected: Bronze would stop being a faithful
  record of what was actually ingested.

## Consequences
- Bronze can always be replayed into Silver and Gold.
- Incremental and snapshot models carry real complexity: two production bugs
  came from state that changes over time rather than from a single run
  (lessons learned, entries 4 and 5).
- dbt snapshots cannot be rebuilt with `--full-refresh`; resetting one means
  dropping the table, and the first version needs backdating to cover
  historical facts.