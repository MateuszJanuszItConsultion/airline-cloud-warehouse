# Contributing

## Commit message convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/). Every commit message should start with a type prefix:

| Prefix | Use for |
|---|---|
| `feat` | New functionality (new models, new DAG tasks, new features) |
| `fix` | Bug fixes |
| `refactor` | Code restructuring without changing behavior |
| `chore` | Maintenance, tooling, configuration, dependencies |
| `docs` | Documentation changes |
| `test` | Adding or changing tests |

Examples:
feat: add dim_aircraft and fact_aircraft_utilization
fix: cast dep_delay/arr_delay via double before rounding
refactor: convert fact tables to incremental models
chore: add sqlfluff for SQL linting
docs: add README with architecture diagram

For commits spanning multiple related changes, use a short title plus a bulleted body:
git commit -m "feat: implement SCD Type 2 tracking for aircraft" -m "- add aircraft_snapshot with check-based change detection
add dim_aircraft_scd2 with surrogate key for point-in-time joins"

## Branch naming

Branch names should match the commit prefix they primarily contain: `feat/short-description`, `fix/short-description`, `chore/short-description`, `refactor/short-description`, `docs/short-description`.

## Pull requests

- All changes to `master` go through a pull request (enforced via branch protection)
- CI must pass before merging (`dbt-build`, `validate-dags`)
- Delete the branch after merging