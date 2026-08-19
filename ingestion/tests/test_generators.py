from datetime import datetime

import pandas as pd

from ingestion.generate_aircraft_utilization import generate_aircraft_utilization
from ingestion.generate_random_flights import generate_flights
from ingestion.generate_weather_data import generate_weather

FIXED_DATE = datetime(2026, 8, 20)


def test_flights_cancelled_have_null_delays(tmp_path):
    path = generate_flights(FIXED_DATE, output_dir=str(tmp_path))
    df = pd.read_parquet(path)

    cancelled = df[df["CANCELLED"] == 1]
    assert cancelled["ARR_DELAY"].isnull().all()
    assert cancelled["DEP_DELAY"].isnull().all()


def test_flights_active_have_delays(tmp_path):
    path = generate_flights(FIXED_DATE, output_dir=str(tmp_path))
    df = pd.read_parquet(path)

    active = df[df["CANCELLED"] == 0]
    assert active["ARR_DELAY"].notnull().all()
    assert active["DEP_DELAY"].notnull().all()


def test_flights_generation_is_deterministic(tmp_path):
    dir_a = tmp_path / "a"
    dir_b = tmp_path / "b"
    dir_a.mkdir()
    dir_b.mkdir()

    path_a = generate_flights(FIXED_DATE, output_dir=str(dir_a))
    path_b = generate_flights(FIXED_DATE, output_dir=str(dir_b))

    df_a = pd.read_parquet(path_a)
    df_b = pd.read_parquet(path_b)

    pd.testing.assert_frame_equal(df_a, df_b)


def test_aircraft_utilization_scheduled_equals_completed_plus_cancelled(tmp_path):
    path = generate_aircraft_utilization(FIXED_DATE, output_dir=str(tmp_path))
    df = pd.read_parquet(path)

    expected = df["COMPLETED_FLIGHT_COUNT"] + df["CANCELLED_FLIGHT_COUNT"]
    assert (df["SCHEDULED_FLIGHT_COUNT"] == expected).all()

def test_aircraft_utilization_grounded_aircraft_have_no_flights(tmp_path):
    path = generate_aircraft_utilization(FIXED_DATE, output_dir=str(tmp_path))
    df = pd.read_parquet(path)

    grounded = df[df["OPERATIONAL_STATUS"] != "Active"]
    assert (grounded["SCHEDULED_FLIGHT_COUNT"] == 0).all()


def test_weather_severe_flag_matches_thresholds(tmp_path):
    path = generate_weather(FIXED_DATE, output_dir=str(tmp_path))
    df = pd.read_parquet(path)

    expected_severe = (
        (df["PRECIPITATION_MM"] > 8)
        | (df["AVG_WIND_SPEED_KMH"] > 30)
        | (df["VISIBILITY_KM"] < 2)
    )
    assert (df["HAS_SEVERE_WEATHER"] == expected_severe.astype(int)).all()  