import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd
import requests

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

BASE_CURRENCY = "USD"
TARGET_CURRENCIES = ["EUR", "GBP", "PLN", "JPY", "CHF", "CAD", "AUD"]

def generate_currency_rates(run_date: datetime, output_dir: str = "data") -> str:
    response = requests.get(
        "https://api.frankfurter.dev/v1/latest",
        params={"base": BASE_CURRENCY, "symbols": ",".join(TARGET_CURRENCIES)},
        timeout=10,
    )
    response.raise_for_status()
    data = response.json()

    rows = [
        {
            "CURRENCY_CODE": code,
            "BASE_CURRENCY": BASE_CURRENCY,
            "RATE_TO_BASE": rate,
            "RATE_DATE": data["date"],
        }
        for code, rate in data["rates"].items()
    ]
    df = pd.DataFrame(rows)

    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"currency_rates_{run_date:%Y%m%d}.parquet")
    df.to_parquet(output_path, index=False)
    print(f"Fetched {len(df)} currency rates for {data['date']} -> {output_path}")
    return output_path

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", type=str, required=True, help="YYYY-MM-DD")
    parser.add_argument("--output-dir", type=str, default="data")
    args = parser.parse_args()

    run_date = datetime.strptime(args.run_date, "%Y-%m-%d")
    generate_currency_rates(run_date, output_dir=args.output_dir)