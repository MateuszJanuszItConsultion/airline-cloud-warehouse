"""
DEPRECATED: Superseded by extraction_and_dbt_dag.py, which includes
the full extraction step (generate + upload + load to bronze) before
running dbt build. Kept paused for reference/comparison.
"""

from airflow.decorators import dag
from airflow.providers.databricks.operators.databricks import DatabricksSubmitRunOperator
from airflow.models import Variable
from pendulum import datetime

WAREHOUSE_ID = Variable.get("DATABRICKS_WAREHOUSE_ID")
CATALOG = Variable.get("DATABRICKS_CATALOG")
GIT_URL = Variable.get("DBT_GIT_URL")
GIT_BRANCH = Variable.get("DBT_GIT_BRANCH")

DBT_TASK_JSON = {
    "run_name": "airline_warehouse_dbt_run",
    "git_source": {
        "git_url": GIT_URL,
        "git_provider": "gitHub",
        "git_branch": GIT_BRANCH,
    },
    "tasks": [
        {
            "task_key": "dbt_build_all",
            "dbt_task": {
                "commands": [
                    "dbt deps",
                    "dbt build",
                ],
                "project_directory": "dbt_project/airline_warehouse",
                "warehouse_id": WAREHOUSE_ID,
                "catalog": CATALOG,
                "schema": "silver",
            },
            "environment_key": "dbt_env",
        }
    ],
    "environments": [
        {
            "environment_key": "dbt_env",
            "spec": {
                "client": "5",
                "dependencies": ["dbt-databricks"],
            },
        }
    ],
}

@dag(
    dag_id="dbt_databricks_job_dag",
    start_date=datetime(2026, 8, 1),
    schedule="0 6 * * *",
    catchup=False,
    tags=["dbt", "databricks", "job"],
)
def dbt_databricks_job_dag():

    submit_dbt_run = DatabricksSubmitRunOperator(
        task_id="submit_dbt_run",
        databricks_conn_id="databricks",
        json=DBT_TASK_JSON,
    )

    submit_dbt_run


dbt_databricks_job_dag()