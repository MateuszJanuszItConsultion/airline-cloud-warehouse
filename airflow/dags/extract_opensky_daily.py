"""DAG: dzienna ekstrakcja danych OpenSky Network do Bronze."""

from datetime import datetime

from airflow.decorators import dag, task


@dag(
    dag_id="extract_opensky_daily",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["ingestion", "opensky"],
)
def extract_opensky_daily():
    @task
    def run_extraction():
        from ingestion.opensky_extractor import extract

        extract()

    run_extraction()


extract_opensky_daily()
