# ADR 0007: Kafka on Aiven with mTLS, and decoupled producer and consumer jobs

## Status
Accepted — recorded retrospectively; decided in September 2026.

## Context
The project needed a real message broker, not only file-based ingestion with
Auto Loader. Databricks Free Edition runs on serverless compute in the cloud,
so it cannot reach a broker on a local machine. Kafka fundamentals were first
learned on a local single-node broker (KRaft) and a local Spark cluster.

## Decision
- **Broker:** Aiven free-tier Kafka. Network reachability from serverless
  Databricks to the broker's non-standard port was tested first, before any
  other work.
- **Authentication:** mutual TLS with client certificates. Certificate contents
  (PEM, private key in PKCS#8) are stored in Databricks Secret Scopes and
  passed inline to the Kafka clients — no certificate files on compute.
- **Producer:** one Python module (`confluent-kafka`) with three configuration
  modes — local plaintext broker, managed broker with certificate files,
  managed broker with Secret Scopes. Keyed by aircraft tail number, with
  `acks=all`, idempotence, and a partitioner matching Java clients
  (lessons learned, entry 2).
- **Consumer:** Spark Structured Streaming with `availableNow` (the only
  streaming trigger available on Free Edition serverless), writing raw
  messages with Kafka coordinates to a Delta table in Bronze.
- **Silver:** a dbt model parses JSON with an explicit schema and routes
  invalid messages to a quarantine table with a reason (`malformed_json`,
  `schema_mismatch`, `key_mismatch`). A singular test asserts every Bronze
  message lands in exactly one of the two outputs.
- **Scheduling:** producer and consumer are separate Databricks jobs with
  independent schedules, run from the Git repository.

## Alternatives considered
- **Kafka on the Airflow VM** — the VM runs about an hour a day, its network
  is locked to one IP, and opening the broker port to serverless egress
  ranges would undo that hardening.
- **SASL/SCRAM** — simpler (username and password), but chosen against in
  favour of certificate-based identity with no shared password.
- **Producer and consumer as consecutive steps of one DAG** — would couple
  the two sides, which is exactly what Kafka exists to avoid.
- **Producer on the Airflow VM** — more realistic separation from the consumer,
  but the VM runs only around the daily schedule.

## Consequences
- The free tier limits topics to two partitions and retention to three days.
  Retention defines the recovery window after a consumer failure, which in
  turn constrains freshness thresholds (ADR 0008).
- Producer and consumer running on the same platform is a deliberate
  simplification: in a real system the producer would be an external system.
- Running Python scripts as Databricks jobs from Git exposed platform details
  that do not appear locally, such as scripts executed without `__file__`.