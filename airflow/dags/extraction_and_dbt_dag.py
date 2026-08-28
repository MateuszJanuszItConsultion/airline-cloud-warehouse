import sys

sys.path.insert(0, "/usr/local/airflow")

from datetime import timedelta

from airflow.decorators import dag, task
from airflow.hooks.base import BaseHook
from airflow.models import Variable
from airflow.providers.databricks.operators.databricks import DatabricksSubmitRunOperator
from airflow.providers.databricks.operators.databricks_sql import DatabricksSqlOperator
from databricks.sdk import WorkspaceClient
from pendulum import datetime

from ingestion.generate_aircraft_utilization import generate_aircraft_utilization
from ingestion.generate_random_flights import generate_flights
from ingestion.generate_weather_data import generate_weather
from ingestion.generate_currency_rates import generate_currency_rates

WAREHOUSE_ID = Variable.get("DATABRICKS_WAREHOUSE_ID")
CATALOG = Variable.get("DATABRICKS_CATALOG")
GIT_URL = Variable.get("DBT_GIT_URL")
GIT_BRANCH = Variable.get("DBT_GIT_BRANCH")

FLIGHTS_VOLUME_PATH = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/flights"
WEATHER_VOLUME_PATH = "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/weather"
AIRCRAFT_UTILIZATION_VOLUME_PATH = (
    "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/aircraft_utilization"
)
CURRENCY_VOLUME_PATH = (
    "/Volumes/airline_cloud_warehouse/bronze/airline_bronze_raw_files/currency_rates"
)

def upload_to_volume(local_path: str, volume_path: str):
    conn = BaseHook.get_connection("databricks")
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
    max_active_runs=1,
    dagrun_timeout=timedelta(hours=8),
    tags=["extraction", "dbt", "databricks"],
    default_args={
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
    },
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

    @task
    def generate_and_upload_aircraft_utilization(logical_date=None):
        run_date = logical_date.replace(tzinfo=None)
        local_path = generate_aircraft_utilization(run_date, output_dir="/usr/local/airflow/data")
        upload_to_volume(local_path, AIRCRAFT_UTILIZATION_VOLUME_PATH)

    @task
    def generate_and_upload_currency(logical_date=None):
        run_date = logical_date.replace(tzinfo=None)
        local_path = generate_currency_rates(run_date, output_dir="/usr/local/airflow/data")
        upload_to_volume(local_path, CURRENCY_VOLUME_PATH)   

    load_flights_to_bronze = DatabricksSqlOperator(
        task_id="load_flights_to_bronze",
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
        databricks_conn_id="databricks",
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

    load_aircraft_utilization_to_bronze = DatabricksSqlOperator(
        task_id="load_aircraft_utilization_to_bronze",
        databricks_conn_id="databricks",
        http_path=f"/sql/1.0/warehouses/{WAREHOUSE_ID}",
        sql=f"""
            COPY INTO {CATALOG}.bronze.aircraft_utilization_raw
            FROM (
                SELECT
                    FL_DATE AS fl_date,
                    AIRCRAFT_KEY AS aircraft_key,
                    AIRPORT_CODE AS airport_code,
                    OPERATIONAL_STATUS AS operational_status,
                    CAST(IS_SCHEDULED_DAY AS INT) AS is_scheduled_day,
                    CAST(SCHEDULED_FLIGHT_COUNT AS INT) AS scheduled_flight_count,
                    CAST(COMPLETED_FLIGHT_COUNT AS INT) AS completed_flight_count,
                    CAST(CANCELLED_FLIGHT_COUNT AS INT) AS cancelled_flight_count,
                    BLOCK_HOURS AS block_hours,
                    FLIGHT_HOURS AS flight_hours,
                    CAST(TOTAL_DISTANCE_KM AS INT) AS total_distance_km,
                    CAST(TOTAL_PASSENGERS_CARRIED AS INT) AS total_passengers_carried,
                    AVAILABLE_SEAT_KILOMETERS AS available_seat_kilometers,
                    REVENUE_PASSENGER_KILOMETERS AS revenue_passenger_kilometers,
                    current_timestamp()   AS _ingested_at,
                    _metadata.file_path   AS _source_file
                FROM '{AIRCRAFT_UTILIZATION_VOLUME_PATH}/'
            )
            FILEFORMAT = PARQUET;
        """,
    )

    load_currency_to_bronze = DatabricksSqlOperator(
        task_id="load_currency_to_bronze",
        databricks_conn_id="databricks",
        http_path=f"/sql/1.0/warehouses/{WAREHOUSE_ID}",
        sql=f"""
            COPY INTO {CATALOG}.bronze.currency_rates_raw
            FROM (
                SELECT
                    CURRENCY_CODE          AS currency_code,
                    BASE_CURRENCY          AS base_currency,
                    RATE_TO_BASE            AS rate_to_base,
                    RATE_DATE               AS rate_date,
                    current_timestamp()     AS _ingested_at,
                    _metadata.file_path     AS _source_file
                FROM '{CURRENCY_VOLUME_PATH}/'
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
    generate_and_upload_aircraft_utilization() >> load_aircraft_utilization_to_bronze
    generate_and_upload_currency() >> load_currency_to_bronze

    [load_flights_to_bronze, load_weather_to_bronze, load_aircraft_utilization_to_bronze, load_currency_to_bronze] >> submit_dbt_run


extraction_and_dbt_dag()
# trigger CI test
#
