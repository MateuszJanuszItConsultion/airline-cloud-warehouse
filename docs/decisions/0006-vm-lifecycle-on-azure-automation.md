# ADR 0006: VM start/stop scheduled by Azure Automation

## Status
Accepted — recorded retrospectively; decided in September 2026.

## Context
To save cost, the Airflow VM runs only for a window around the daily DAG run.
The first implementation used scheduled GitHub Actions workflows with a
Service Principal. In practice, the start workflow scheduled for 05:50 UTC
ran at 13:52 (lessons learned, entry 6) — so the VM was not running when
Airflow needed it.

## Decision
- Start and stop are Azure Automation runbooks (PowerShell, `Start-AzVM`,
  `Stop-AzVM -Force`, which deallocates the VM and stops compute billing).
- Runbooks authenticate with the Automation Account's System-assigned Managed
  Identity, granted `Virtual Machine Contributor` on the resource group only.
- Schedules are defined in local time (Europe/Warsaw) instead of UTC cron.
- The GitHub Actions workflows remain with `workflow_dispatch` only, as a
  manual fallback.

## Alternatives considered
- **Keep GitHub Actions `schedule`** — scheduled workflows are best-effort and
  can run late or be skipped; acceptable for jobs that tolerate jitter, not
  for infrastructure that other schedules depend on.
- **Service Principal with a client secret** — works, but requires storing and
  rotating a secret; a Managed Identity has no secret at all.

## Consequences
- A scheduler native to the platform it controls, with no credentials stored
  outside Azure.
- The Automation Account lives in North Europe, not next to the VM: the Free
  Trial subscription does not allow Automation Accounts in Poland Central.
  The region does not matter for managing the VM.
- The first GitHub Actions version was still useful: measuring its actual
  timing is what justified the migration.