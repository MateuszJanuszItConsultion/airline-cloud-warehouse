import sys
sys.path.insert(0, "/usr/local/airflow")

from airflow.decorators import dag, task
from airflow.providers.databricks.operators.databricks import DatabricksSubmitRunOperator
from airflow.providers.databricks.operators.databricks_sql import DatabricksSqlOperator
from airflow.hooks.base import BaseHook
from airflow.models import Variable
from databricks.sdk import WorkspaceClient
from pendulum import datetime

from ingestion.generate_random_flights import generate_flights

WAREHOUSE_ID = Variable.get("DATABRICKS_WAREHOUSE_ID")
CATALOG = Variable.get("DATABRICKS_CATALOG")
GIT_URL = Variable.get("DBT_GIT_URL")
GIT_BRANCH = Variable.get("DBT_GIT_BRANCH")

VOLUME_PATH = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/flights"


@dag(
    dag_id="extraction_and_dbt_dag",
    start_date=datetime(2026, 8, 1),
    schedule="0 6 * * *",
    catchup=False,
    tags=["extraction", "dbt", "databricks"],
)
def extraction_and_dbt_dag():

    @task
    def generate_and_upload(logical_date=None):
        run_date = logical_date.replace(tzinfo=None)
        local_path = generate_flights(run_date, output_dir="/usr/local/airflow/data")

        conn = BaseHook.get_connection("databricks")
        client = WorkspaceClient(host=conn.host, token=conn.password)

        file_name = local_path.split("/")[-1]
        remote_path = f"{VOLUME_PATH}/{file_name}"

        with open(local_path, "rb") as f:
            client.files.upload(remote_path, f, overwrite=True)

        print(f"Uploaded {local_path} -> {remote_path}")

    load_to_bronze = DatabricksSqlOperator(
        task_id="load_to_bronze",
        databricks_conn_id="databricks",
        http_path=f"/sql/1.0/warehouses/{WAREHOUSE_ID}",
        sql=f"""
            COPY INTO {CATALOG}.bronze.flights_raw
            FROM (
                SELECT
                    FL_DATE            AS fl_date,
                    OP_CARRIER         AS op_carrier,
                    OP_FL_NUM          AS op_carrier_fl_num,
                    ORIGIN             AS origin,
                    DEST               AS dest,
                    DEP_DELAY          AS dep_delay,
                    ARR_DELAY          AS arr_delay,
                    CANCELLED          AS cancelled,
                    current_timestamp() AS _ingested_at,
                    _metadata.file_path AS _source_file
                FROM '{VOLUME_PATH}/'
            )
            FILEFORMAT = PARQUET;
        """,
    )

    submit_dbt_run = DatabricksSubmitRunOperator(
        task_id="submit_dbt_run",
        databricks_conn_id="databricks",
        json={
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
                        "commands": ["dbt deps", "dbt build"],
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
                    "spec": {"client": "5", "dependencies": ["dbt-databricks"]},
                }
            ],
        },
    )

    generate_and_upload() >> load_to_bronze >> submit_dbt_run


extraction_and_dbt_dag()