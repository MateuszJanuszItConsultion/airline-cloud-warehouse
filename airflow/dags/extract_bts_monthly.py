"""DAG: miesięczna ekstrakcja danych BTS (Bureau of Transportation Statistics) do Bronze."""

from datetime import datetime

from airflow.decorators import dag, task


@dag(
    dag_id="extract_bts_monthly",
    schedule="@monthly",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["ingestion", "bts"],
)
def extract_bts_monthly():
    @task
    def run_extraction():
        from ingestion.bts_extractor import extract

        extract()

    run_extraction()


extract_bts_monthly()
