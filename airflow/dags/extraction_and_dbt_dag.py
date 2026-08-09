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
from ingestion.generate_weather_data import generate_weather

WAREHOUSE_ID = Variable.get("DATABRICKS_WAREHOUSE_ID")
CATALOG = Variable.get("DATABRICKS_CATALOG")
GIT_URL = Variable.get("DBT_GIT_URL")
GIT_BRANCH = Variable.get("DBT_GIT_BRANCH")

FLIGHTS_VOLUME_PATH = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/flights"
WEATHER_VOLUME_PATH = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/weather"

def upload_to_volume(local_path: str, volume_path: str):
    conn = BaseHook.get_connection("databricks_default")
    client = WorkspaceClient(host=conn.host, token=conn.password)

    file_name = local_path.split("/")[-1]
    remote_path = f"{volume_path}/{file_name}"

    with open(local_path, "rb") as f:
        client.files.upload(remote_path, f, overwrite=True)

    print(f"Uploaded {local_path} -> {remote_path}")

@dag(
    dag_id="extraction_and_dbt_dag",
    start_date=datetime(2026, 8, 1),
    schedule="0 6 * * *",
    catchup=False,
    tags=["extraction", "dbt", "databricks"],
)
def extraction_and_dbt_dag():

    @task
    def generate_and_upload_flights(logical_date=None):
        run_date = logical_date.replace(tzinfo=None)
        local_path = generate_flights(run_date, output_dir="/usr/local/airflow/data")
        upload_to_volume(local_path, FLIGHTS_VOLUME_PATH)

    @task
    def generate_and_upload_weather(logical_date=None):
        run_date = logical_date.replace(tzinfo=None)
        local_path = generate_weather(run_date, output_dir="/usr/local/airflow/data")
        upload_to_volume(local_path, WEATHER_VOLUME_PATH)

    load_flights_to_bronze = DatabricksSqlOperator(
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
                FROM '{FLIGHTS_VOLUME_PATH}/'
            )
            FILEFORMAT = PARQUET;
        """,
    )

    load_weather_to_bronze = DatabricksSqlOperator(
        task_id="load_weather_to_bronze",
        databricks_conn_id="databricks_default",
        http_path=f"/sql/1.0/warehouses/{WAREHOUSE_ID}",
        sql=f"""
            COPY INTO {CATALOG}.bronze.weather_raw
            FROM (
                SELECT
                    OBS_DATE              AS obs_date,
                    AIRPORT_CODE          AS airport_code,
                    AVG_TEMP_C            AS avg_temp_c,
                    PRECIPITATION_MM      AS precipitation_mm,
                    AVG_WIND_SPEED_KMH    AS avg_wind_speed_kmh,
                    VISIBILITY_KM         AS visibility_km,
                    HAS_SEVERE_WEATHER    AS has_severe_weather,
                    current_timestamp()   AS _ingested_at,
                    _metadata.file_path   AS _source_file
                FROM '{WEATHER_VOLUME_PATH}/'
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

    generate_and_upload_flights() >> load_flights_to_bronze
    generate_and_upload_weather() >> load_weather_to_bronze

    [load_flights_to_bronze, load_weather_to_bronze] >> submit_dbt_run


extraction_and_dbt_dag()