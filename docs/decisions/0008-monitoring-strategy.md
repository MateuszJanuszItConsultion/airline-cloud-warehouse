# ADR 0008: Monitoring strategy — processes and data, independent of what is monitored

## Status
Accepted — recorded retrospectively; decided in September 2026.

## Context
Before this decision, every failure — a failed Airflow task, a failed or hung
Databricks job, data that stopped arriving — was visible only to someone who
opened the UI. The most dangerous failures were silent: nothing failed, data
simply stopped flowing. With Kafka retention of three days, an unnoticed
consumer outage means permanent data loss.

## Decision
- **One channel:** email.
- **Process monitoring:**
  - Databricks jobs: failure notifications, a timeout (a hung job becomes a
    failed job), and a duration warning.
  - Airflow: `SmtpNotifier` as `on_failure_callback` on every task — one email
    per task that actually fails, naming the DAG and task with a link to the
    log. (`email_on_failure` is deprecated in Airflow 3.)
- **Data monitoring:** `dbt source freshness` over all Bronze sources, run as
  its own scheduled Databricks job. Thresholds derive from job schedules —
  warn after one missed run, error after two — and leave margin to react
  before Kafka retention drops data.
- **Independence:** the freshness check runs on Databricks, not in Airflow,
  so it still alerts if the Airflow VM never starts.
- **Verification:** every alert path was fire-drilled — broken deliberately,
  alert confirmed, then restored and confirmed healthy.

## Alternatives considered
- **Failure notifications only** — cannot detect paused or never-scheduled
  jobs. The first run of the freshness check found exactly that: a paused
  ingestion job (lessons learned, entry 7).
- **A dedicated Kafka consumer-lag alert** — rejected for now: with
  `availableNow`, lag can only grow when the consumer stops running, which is
  already covered by job failure alerts and freshness. A third alert for the
  same event would add noise. Revisit if the consumer moves to continuous
  streaming.

## Consequences
- Freshness thresholds and job schedules are two configurations that must
  agree; a comment next to the thresholds records the dependency.
- Warnings are visible only in job output; only errors send email. A
  deliberate trade-off to keep alerts rare enough to be read.
- Databricks failure emails are generic and require opening the run to see
  which source is stale.