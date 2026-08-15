import argparse
import sys
import pandas as pd
import numpy as np
from datetime import datetime
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from ingestion.reference_data import load_airport_codes
from ingestion.validation import validate_weather

AIRPORTS = load_airport_codes()

def generate_weather(run_date: datetime, output_dir: str = "data"):
    np.random.seed(int(run_date.strftime("%Y%m%d")) + 1)

    rows = []
    for airport in AIRPORTS:
        avg_temp_c = np.random.normal(loc=15, scale=10)
        precipitation_mm = max(0, np.random.exponential(scale=3))
        avg_wind_speed_kmh = max(0, np.random.normal(loc=15, scale=8))
        visibility_km = np.clip(np.random.normal(loc=12, scale=4), 0.5, 20)
        has_severe_weather = int(precipitation_mm > 8 or avg_wind_speed_kmh > 30 or visibility_km < 2)

        rows.append({
            'OBS_DATE': run_date.strftime('%Y-%m-%d'),
            'AIRPORT_CODE': airport,
            'AVG_TEMP_C': round(avg_temp_c, 1),
            'PRECIPITATION_MM': round(precipitation_mm, 1),
            'AVG_WIND_SPEED_KMH': round(avg_wind_speed_kmh, 1),
            'VISIBILITY_KM': round(visibility_km, 1),
            'HAS_SEVERE_WEATHER': has_severe_weather,
        })

    df = pd.DataFrame(rows)
    output_path = f"{output_dir}/weather_{run_date:%Y%m%d}.parquet"
    validate_weather(df)
    df.to_parquet(output_path, index=False)
    print(f"Generated {len(df)} weather rows for {run_date.date()} -> {output_path}")
    return output_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", type=str, required=True)
    parser.add_argument("--output-dir", type=str, default="data")
    args = parser.parse_args()

    run_date = datetime.strptime(args.run_date, "%Y-%m-%d")
    generate_weather(run_date, output_dir=args.output_dir)