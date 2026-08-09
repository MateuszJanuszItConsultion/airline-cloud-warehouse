import argparse
import pandas as pd
import numpy as np
from datetime import datetime, timedelta


def generate_flights(run_date: datetime, n_rows: int = 500, output_dir: str = "data"):
    np.random.seed(int(run_date.strftime("%Y%m%d")))

    start_date = run_date - timedelta(days=6)
    dates = [start_date + timedelta(days=int(i)) for i in np.random.randint(0, 7, size=n_rows)]

    carriers = ['AA', 'DL', 'UA', 'WN', 'B6']
    airports = ['JFK', 'LAX', 'ORD', 'DFW', 'DEN', 'SFO', 'ATL', 'MIA']

    origins = np.random.choice(airports, size=n_rows)
    destinations = [np.random.choice([a for a in airports if a != o]) for o in origins]

    dep_delays = np.random.normal(loc=5, scale=15, size=n_rows).round(1)
    arr_delays = dep_delays + np.random.normal(loc=0, scale=10, size=n_rows).round(1)

    cancelled = np.random.choice([0, 1], size=n_rows, p=[0.98, 0.02])
    dep_delays = [None if c == 1 else d for d, c in zip(dep_delays, cancelled)]
    arr_delays = [None if c == 1 else a for a, c in zip(arr_delays, cancelled)]

    flight_numbers = np.random.randint(100, 9999, size=n_rows)

    df = pd.DataFrame({
        'FL_DATE': [d.strftime('%Y-%m-%d') for d in dates],
        'OP_CARRIER': np.random.choice(carriers, size=n_rows),
        'OP_FL_NUM': flight_numbers,
        'ORIGIN': origins,
        'DEST': destinations,
        'DEP_DELAY': dep_delays,
        'ARR_DELAY': arr_delays,
        'CANCELLED': cancelled
    })

    output_path = f"{output_dir}/flights_{run_date:%Y%m%d}.parquet"
    df.to_parquet(output_path, index=False)
    print(f"Generated {n_rows} rows for week ending {run_date.date()} -> {output_path}")
    return output_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", type=str, required=True, help="YYYY-MM-DD")
    parser.add_argument("--output-dir", type=str, default="data")
    args = parser.parse_args()

    run_date = datetime.strptime(args.run_date, "%Y-%m-%d")
    generate_flights(run_date, output_dir=args.output_dir)