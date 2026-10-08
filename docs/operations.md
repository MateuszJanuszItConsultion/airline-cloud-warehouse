# Operations

How the system is run, monitored, frozen and restored. Architecture is described in [architecture.md](architecture.md); infrastructure commands are in [infra/terraform/README.md](../infra/terraform/README.md).

## Monitoring and alerts

All alerts are delivered by email. The reasoning is in [ADR 0008](decisions/0008-monitoring-strategy.md).

| Alert | Raised by | Means | First response |
|---|---|---|---|
| Databricks job failed | Job failure notification | A job ended with an error | Open the run from the email; check the failing task's output |
| Databricks job exceeded duration / timed out | Duration warning, job timeout | A job hung or slowed down; a timeout turns it into a failure | Check whether the run waited for compute or stalled inside the code; cancel and re-run if it was a one-off |
| Airflow task failed | `SmtpNotifier` (`on_failure_callback`) | A task failed after all retries | Follow the log link in the email (requires the SSH tunnel) |
| Source freshness error | Freshness job (`dbt source freshness`) | A Bronze source has not received data for longer than its error threshold | Identify the stale source in the job output, then check its ingestion job or the Airflow DAG run |

Notes:
- Freshness thresholds are derived from job schedules (warn after one missed run, error after two). **Changing a job schedule requires revisiting the thresholds** in `_sources.yml`.
- Freshness warnings appear only in job output; only errors send email.
- The freshness job runs on Databricks, independent of Airflow, so it also detects the Airflow VM not starting.
- Every alert path was verified with a deliberate failure. After changing alerting, repeat the drill: break it, confirm the alert arrives, restore, confirm healthy.

## Routine operations

### Deploying changes
Merge to `master` through a pull request. CI must pass. Changes under `airflow/`, `ingestion/` or `dbt_project/` are pulled onto the VM by the self-hosted runner; Airflow restarts only when the image or container configuration changed ([ADR 0005](decisions/0005-self-hosted-runner-for-deployment.md)). Databricks jobs run code from the repository, so merged changes apply on their next run.

### Reprocessing streaming data
- **Never delete only a streaming checkpoint.** Reset the checkpoint and its output together, or not at all ([lessons learned, entry 1](lessons-learned.md)).
- On Delta, `RESTORE TABLE` does not rewind the checkpoint. Use it only when the restored version contains exactly what the checkpoint recorded.
- Reprocessing from Kafka is possible only within the topic's retention (three days on the Aiven free tier).
- After any reprocessing, reconcile: Kafka end offsets per partition vs. `count(DISTINCT partition, offset)` in Bronze.

### Adding a new Bronze source
Add its DDL to `sql/bronze_ddl/`, declare it in `_sources.yml` with a freshness threshold matching its schedule, and give its Silver model a deduplication key that matches what a row means.

## Freezing the project

The project is frozen as a completed portfolio piece. Freezing means no running infrastructure, no live credentials, and a repository that still passes CI.

1. **Pause Databricks job schedules** through the Asset Bundle (`pause_status: PAUSED`) and deploy, so the paused state is recorded in code rather than set in the UI.
2. **Remove Azure compute with Terraform** — the Airflow VM and the Automation Account. Release the management lock first (it is controlled by a variable). Keep the Terraform state backend: without it the infrastructure cannot be restored from code.
3. **Decide what stays in Databricks.** The catalog, schemas and volumes cost nothing at rest and can remain.
4. **Shut down Aiven.** It is not managed by Terraform; delete or power off the service in the Aiven console.
5. **Revoke credentials** rather than leaving them valid:
   - Databricks tokens used by CI and Airflow
   - the OpenSky API client
   - the Gmail app password used for SMTP alerts
   - Aiven client certificates are invalidated with the service
6. **Deregister the self-hosted runner** in GitHub, and disable the VM deployment workflow — with no runner, its jobs would queue indefinitely.
7. **Disable Dependabot** so it does not open pull requests against a frozen project.
8. **Mark the project as frozen** at the top of the README, with a link to the restore procedure below.

## Restoring the project

Prerequisites: an Azure subscription, a Databricks workspace, an Aiven account, a GitHub fork or clone, and locally `terraform`, the Databricks CLI, the Azure CLI and `uv`.

1. **Python environment:** `uv sync`, then `uv run pre-commit install --hook-type pre-commit --hook-type commit-msg`.
2. **Terraform state:** sign in with the Azure CLI and initialise each root module against the existing remote backend (partial backend configuration — see the infrastructure README).
3. **Azure infrastructure:** `terraform apply` for the `prod` environment — network, VM, Automation Account, budget. Update the NSG's allowed source IP to the current one.
4. **Aiven:** create a free-tier Kafka service, create the `aircraft-telemetry` topic, download the CA certificate, client certificate and private key (PKCS#8). Check reachability from Databricks serverless before anything else (a plain TCP connection test from a notebook).
5. **Secrets:** issue new credentials — Databricks token, OpenSky API client, Aiven certificates, Gmail app password — and apply them through Terraform (secret scopes, write-only values), GitHub Actions secrets, and local `.env` files.
6. **Databricks platform:** `terraform apply` for the Databricks root module — catalog, schemas, volumes, grants, secret scopes.
7. **Airflow on the VM:** install Docker and the Astro CLI, clone the repository, create `airflow/.env` (Databricks connection, SMTP connection, `ALERT_EMAIL`), set ownership of mounted data directories to UID `50000`, install the `systemd` unit that starts Airflow on boot, apply host hardening (key-only SSH, `fail2ban`, `unattended-upgrades`), and register a new self-hosted runner with the `azure-airline-vm` label.
8. **Jobs:** `databricks bundle deploy`, then set job schedules back to unpaused.
9. **Verify end to end:** trigger the DAG manually, run each Databricks job once, run the freshness check, reconcile Kafka offsets with Bronze, and fire-drill one alert.

Order matters: jobs depend on volumes and secret scopes created by Terraform ([ADR 0001](decisions/0001-platform-and-jobs-ownership.md)), and the consumer depends on the Aiven topic existing — automatic topic creation is disabled by design.