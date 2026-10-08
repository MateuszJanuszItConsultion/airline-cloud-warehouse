# ADR 0004: Self-hosted Airflow on an Azure VM

## Status
Accepted — recorded retrospectively; decided in August 2026.

## Context
Airflow ran only locally (Astro CLI in Docker), so scheduled runs depended on
a development laptop being on. The goal was a cloud-hosted Airflow on a
learning budget, deployed in a way that resembles a real self-managed setup.

## Decision
- Airflow runs on an Azure VM (Ubuntu 24.04, x64, `Standard_D2as_v5`,
  Poland Central) using the Astro CLI in Docker, started by a `systemd` unit
  on boot.
- The Airflow UI is not exposed publicly; access is through an SSH tunnel only.
- Host hardening: NSG allows SSH only from a single IP, key-only SSH
  (password authentication disabled), `fail2ban`, `unattended-upgrades`.
- Mounted data directories are owned by the container UID (`50000`),
  not opened with world-writable permissions.
- The infrastructure was later imported into Terraform without downtime.

## Alternatives considered
- **Astro Cloud (managed Airflow)** — no permanent free tier; a time-limited
  trial only.
- **Oracle Cloud Always Free** — the most generous free VM, but repeated
  "out of host capacity" errors, an ARM-only free shape, and a risk of idle
  instances being reclaimed.
- **GitHub Actions as the scheduler** — free, but replaces Airflow rather than
  hosting it.
- **Smaller burstable VM sizes** — the preferred sizes were not available for
  a Free Trial subscription in the region.

## Consequences
- Running cost from Azure credit, mitigated by running the VM only around
  the daily schedule (ADR 0006).
- `astro dev` runs Airflow with an auth manager that treats every user as
  admin. This is acceptable only because the network layer is the security
  boundary: the UI is reachable exclusively through the SSH tunnel.
- Automated SSH brute-force attempts appeared in `auth.log` within the first
  hour of the VM having a public IP — before the NSG rule was narrowed.
- A dynamic home IP address can lock out SSH until the NSG rule is updated.