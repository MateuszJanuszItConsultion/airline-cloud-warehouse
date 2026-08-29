import subprocess
import sys

result = subprocess.run(
    ["sqlfluff", "lint", "models/"],
    cwd="dbt_project/airline_warehouse",
)
sys.exit(result.returncode)