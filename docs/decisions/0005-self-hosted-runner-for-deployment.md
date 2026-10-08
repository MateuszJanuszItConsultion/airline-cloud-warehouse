# ADR 0005: Self-hosted GitHub Actions runner for deployments to the VM

## Status
Accepted — recorded retrospectively; decided in September 2026.

## Context
Code merged to `master` had to reach the Airflow VM without manual SSH
sessions. The obvious approach — a GitHub-hosted runner connecting to the VM
over SSH — requires a private key stored in GitHub Secrets and an inbound
SSH rule open to GitHub's address ranges.

## Decision
- A self-hosted runner is installed on the VM as a `systemd` service. It opens
  an outbound HTTPS connection to GitHub and picks up jobs; nothing inbound
  is opened.
- The deploy workflow targets the runner by labels
  (`[self-hosted, azure-airline-vm]`), not by the generic `self-hosted` label.
- Deployment: `git reset --hard origin/master`, then restart Airflow **only**
  when the image or container configuration changed (`requirements.txt`,
  `packages.txt`, `Dockerfile`, `docker-compose.override.yml`). DAG, ingestion
  and dbt files are bind-mounted and picked up without a restart.
- After deployment, DAG import errors are checked and fail the job.

## Alternatives considered
- **SSH key in GitHub Secrets** — simpler, but places a credential with shell
  access to the VM outside it, and requires inbound SSH from GitHub.
- **Restart on every deployment** — rejected: the VM runs only around the DAG
  schedule, so queued deployments start right before the DAG run and an
  unnecessary restart could interrupt it.

## Consequences
- No deployment credentials stored in GitHub.
- The runner is online only while the VM runs; deployments queue until then.
- Anyone able to merge to `master` can execute code on the VM — branch
  protection is the security boundary.
- A green deployment means the DAGs actually import, not just that commands ran.