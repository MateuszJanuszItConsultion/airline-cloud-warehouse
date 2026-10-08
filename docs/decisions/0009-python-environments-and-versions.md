# ADR 0009: Python environment management with uv, and one Python version per runtime

## Status
Accepted — recorded retrospectively; decided in October 2026.

## Context
Tools were installed into a global Python. An inventory found three
interpreters on the development machine, with different tools on different
versions (lessons learned, entry 9). CI workflows installed packages without
pinned versions, so local and CI environments could differ. Production code
runs in two places with different Python versions: Databricks serverless
(3.12) and the Airflow Astro image (3.14).

## Decision
- **uv manages the project environment.** `pyproject.toml` defines dependency
  groups (`dev`, `ingestion`, `dbt`); `uv.lock` pins the full dependency
  graph and is committed. CI installs with `uv sync --locked`, so a lock file
  out of sync with `pyproject.toml` fails the build.
- **Migration first, upgrades later.** Direct dependencies were pinned to the
  versions that already worked; upgrades are a separate change.
- **The project develops on Python 3.12** — the oldest production runtime of
  its code. Code verified on 3.12 also runs on 3.14; the reverse is not
  guaranteed. Ruff's `target-version` matches.
- **Airflow DAG import tests run on 3.14**, matching the Astro image, in a
  separate environment built from `airflow/requirements.txt`.
- **Outside uv by design:** the Astro image (Astronomer pins its own Airflow
  dependencies) and Databricks job environments (managed by serverless).
- `uv.lock` is forced to LF line endings via `.gitattributes`, to avoid
  spurious diffs on Windows checkouts.

## Alternatives considered
- **Latest Python everywhere** — would mean developing on a version no
  production runtime uses.
- **One lock file for everything, including the Astro image** — risks
  conflicts with the dependencies Astronomer pins for Airflow.
- **Upgrading dependencies during the migration** — rejected: a failure
  could not be attributed to either the migration or a new library version.

## Consequences
- Three Python versions exist by design, each tied to where code runs.
- Changing the Python version touched only `.python-version`,
  `requires-python` and the lock file; no package version changed.
- Pre-existing warnings carried over unchanged (`requests` vs. `chardet`
  pulled in by sqlfluff), to be resolved by the dependency upgrade.