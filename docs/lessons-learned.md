# Lessons learned

This document collects incidents and discoveries from building and running this project, written as short postmortems: what happened, how it was detected, the root cause, the fix, and what it changed in how I work.

Most entries share one property: **nothing visibly failed**. Pipelines kept running, tests stayed green, and the problem surfaced only because a number was checked against an expectation. That is the main reason this document exists.

## Recurring pattern: two sources of truth that must agree

Several unrelated incidents turned out to be the same problem in different places — two independent records of the same fact drifting apart, with nothing reconciling them:

| Where | The two sources of truth |
|---|---|
| Structured Streaming | Checkpoint vs. the sink's own commit log |
| Kafka producers | Python client partitioner vs. Java client partitioner |
| Monitoring | Job schedules vs. freshness thresholds |
| Python environments | Local interpreter vs. production runtimes |

Where such a pair exists, the project now either removes one side, or adds a check that compares them.

---

## 1. Deleting a streaming checkpoint: silent data loss on Parquet, duplicates on Delta

**Context.** A Kafka consumer built with Spark Structured Streaming wrote to a sink with a durable checkpoint. To "reprocess" data, only the checkpoint was deleted.

**What happened.**
- **Parquet sink (local Spark cluster):** after deleting the checkpoint and producing 25 new messages, the consumer reported zero rows read, and Bronze row count did not change. The 25 messages were lost, and the new checkpoint recorded them as processed.
- **Delta sink (Databricks):** the same operation wrote every message a second time.

**Detection.** Comparing Bronze row counts before and after, and counting distinct `(partition, offset)` pairs against Kafka end offsets. No warning appeared at the default log level.

**Root cause.** A streaming query has two independent memories: the checkpoint (which offsets were read, under which batch ID) and the sink's own log of committed batches. Deleting only the checkpoint restarts batch numbering at zero.
- The Parquet file sink keeps a `_spark_metadata` log and skips batch IDs it believes are already committed — so new data is silently dropped. Because the batch is skipped, the source is never even read, which is why the input row count was zero.
- Delta identifies idempotent writes by the query ID stored in the checkpoint. A new checkpoint means a new query, so Delta cannot recognise the replay and appends duplicates.

**Fix.** Full rebuild — delete both checkpoint and output — while the data was still within Kafka retention. On Delta, `RESTORE TABLE` removed the duplicates, but only because the restored version matched exactly what the new checkpoint had recorded. `RESTORE` does not rewind the checkpoint: it is a separate folder, not table metadata.

**Takeaway.** A checkpoint and its output are reset together or not at all. Recovery depends on the source still holding the data, so retention defines the recovery window. A reconciliation query (Kafka offsets vs. unique offsets in Bronze) is the only reliable way to see this class of failure.

---

## 2. The same Kafka key landed in different partitions depending on the client

**Context.** Telemetry messages are keyed by aircraft tail number, so all events for one aircraft stay in one partition and keep their order.

**What happened.** A key sent from the Kafka console producer always landed in partition 0. The same key sent from the Python producer landed in partition 1.

**Detection.** Comparing partition numbers in delivery reports against earlier observations from the console tools.

**Root cause.** Java clients hash keys with murmur2. librdkafka, used by the Python `confluent-kafka` client, defaults to a different partitioner (CRC32-based). Same key, same topic, same partition count — different partition. Kafka gives no warning.

**Fix.** `partitioner: murmur2_random` in the Python producer configuration, verified against the console producer afterwards.

**Takeaway.** "The same key always goes to the same partition" holds only within one client implementation. With mixed producers, per-key ordering can break without any visible error.

---

## 3. A topic silently created with one partition

**What happened.** After recreating the local broker, a topic intended to have three partitions ended up with one.

**Detection.** The last message in partition 0 had offset 201 while the consumer had read 202 messages in total — meaning every message was in partition 0.

**Root cause.** The producer ran before the topic was created. With automatic topic creation enabled (the default), the broker created it with the default single partition, and the later explicit `--create` failed because the topic already existed.

**Fix.** `auto.create.topics.enable=false` on the broker, verified by producing to a misspelled topic name. The producer also checks topic metadata at startup and exits with a non-zero code if the topic does not exist, instead of retrying for minutes and dropping messages on shutdown.

**Takeaway.** A topic is a design decision (partitions, retention), not a side effect of the first message.

---

## 4. A snapshot broke weeks after it was written, as history accumulated

**Context.** `currency_snapshot` (SCD Type 2) was built when the staging model held one exchange rate per currency.

**What happened.** Weeks later, an unrelated pull request failed CI with `DELTA_MULTIPLE_SOURCE_ROW_MATCHING_TARGET_ROW_IN_MERGE`.

**Root cause.** As daily runs accumulated, the staging model correctly kept one row per currency **per day**. The snapshot's source query now returned several rows per `unique_key`, and `MERGE` cannot decide which one to apply.

**Fix.** Deduplicate the snapshot source to the latest rate per currency with `ROW_NUMBER()` before the snapshot logic.

**Takeaway.** Some bugs are invisible until data grows into them. Running the full `dbt build` on every pull request caught this one before it reached `master` — and only because CI builds against real accumulated data, not a fixture.

---

## 5. An accumulating snapshot silently erased milestone timestamps

**Context.** `fact_flight_lifecycle` holds one row per flight, updated in place as lifecycle events arrive (scheduled, boarding, departed, landed, arrived), using incremental `merge` with `merge_update_columns`.

**What happened.** After a `boarding` event arrived for a flight that already had `scheduled_at`, the merge set `scheduled_at` to `NULL`. All dbt tests passed.

**Detection.** A deliberate test: injecting a later event for an existing flight and checking that both timestamps survived.

**Root cause.** `merge_update_columns` controls **which** columns may be updated, not **with what**. The incremental batch contained only the new event, so the pivot computed `NULL` for `scheduled_at`, and `MERGE` dutifully wrote it.

**Fix.** Join the new batch to the existing table (`{{ this }}`) and keep prior values with `COALESCE(new, existing)` per milestone column.

**Takeaway.** Tests that check a single snapshot of state (`not_null`, `accepted_values`) cannot catch bugs in how state changes over time. An accumulating snapshot needs a test of its update behaviour, not only of its contents.

---

## 6. GitHub Actions cron started the VM eight hours late

**Context.** Scheduled GitHub Actions workflows started and stopped the Azure VM hosting Airflow around the daily DAG run.

**What happened.** The start workflow, scheduled for 05:50 UTC, ran at 13:52.

**Root cause.** GitHub Actions scheduled workflows are best-effort: delays are documented, and under load runs can be significantly late or skipped.

**Fix.** Migrated VM start/stop to Azure Automation runbooks with a System-assigned Managed Identity — a scheduler native to the platform it controls, with no credentials stored in GitHub.

**Takeaway.** A CI system is a good scheduler for jobs that tolerate jitter, not for infrastructure lifecycle that other schedules depend on. The first version was still worth building: measuring it is what justified the migration.

---

## 7. A paused job was invisible to failure alerts

**Context.** Databricks jobs had failure notifications and timeouts configured.

**What happened.** The first run of a new data freshness check reported OpenSky data older than its warning threshold. The ingestion job had been paused — something no failure notification can detect, because a paused job never fails.

**Fix.** Freshness checks became a scheduled job that alerts on stale data, with thresholds derived from job schedules (warn after one missed run, error after two) and from Kafka retention (enough margin to react before data expires).

**Follow-up.** The freshness job was extended to all Bronze sources and runs on Databricks, independent of Airflow — so if the VM hosting Airflow never starts, the alert still arrives.

**Takeaway.** Process monitoring ("did the job fail?") and data monitoring ("is data still arriving?") catch different failures, and both are needed. Monitoring must not depend on the system it monitors.

---

## 8. Late-arriving data and the incremental watermark

**Context.** Fact tables load incrementally.

**Root cause of the risk.** The data generator produces records within a sliding window of dates, so a run can deliver rows for earlier business dates. A watermark on the business date (`flight_date > max(flight_date)`) would silently skip them.

**Fix.** Incremental filters use the technical load timestamp (`_ingested_at`), which only moves forward, combined with `merge` on the business key.

**Takeaway.** An incremental watermark must be monotonic with respect to loading, not to business time.

---

## 9. Three Python interpreters, and code tested on a version production never used

**What happened.** While migrating to uv, an inventory showed three interpreters on the development machine. `python` resolved to 3.11, dbt and sqlfluff ran on 3.13, and the Kafka producer had been installed into 3.11. Production ran yet other versions: Databricks serverless on 3.12, the Airflow (Astro) image on 3.14.

**Fix.**
- Project environment managed by uv with a lock file; direct dependencies pinned to the versions that already worked ("migrate first, upgrade later").
- The project develops on Python 3.12 — the oldest production runtime of its code, because code verified on 3.12 also runs on 3.14, but not necessarily the other way round.
- Airflow DAG import tests run on 3.14 to match the Astro image.
- CI installs from the lock file; previously several CI workflows installed unpinned packages, so local and CI versions could differ.

**Takeaway.** "It works on my machine" was literally true and not useful — the machine itself was inconsistent. Each environment's Python version is now an explicit decision tied to where the code actually runs.