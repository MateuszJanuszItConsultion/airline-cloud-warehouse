import argparse
import json
import os
import sys
import uuid
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ingestion.reference_data import load_airport_codes, load_carriers

EVENT_TYPES = ["scheduled", "boarding", "departed", "landed", "arrived"]


def generate_flight_events(run_date: datetime, output_dir: str = "data/flight_events", n_flights: int = 5) -> list[str]:
    np.random.seed(int(run_date.strftime("%Y%m%d")))
    airports = load_airport_codes()
    carriers = load_carriers()

    os.makedirs(output_dir, exist_ok=True)
    written_files = []

    for i in range(n_flights):
        flight_number = int(np.random.randint(100, 9999))
        carrier = np.random.choice(carriers)
        origin, dest = np.random.choice(airports, size=2, replace=False)
        event_type = np.random.choice(EVENT_TYPES)

        event = {
            "event_id": str(uuid.uuid4()),
            "flight_date": run_date.strftime("%Y-%m-%d"),
            "carrier_code": carrier,
            "flight_number": flight_number,
            "origin_airport": origin,
            "dest_airport": dest,
            "event_type": event_type,
            "event_timestamp": (run_date + timedelta(minutes=int(np.random.randint(0, 1440)))).isoformat(),
        }

        file_path = os.path.join(output_dir, f"event_{event['event_id']}.json")
        with open(file_path, "w") as f:
            json.dump(event, f)
        written_files.append(file_path)

    print(f"Generated {len(written_files)} flight events for {run_date.date()} -> {output_dir}")
    return written_files


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", type=str, required=True)
    parser.add_argument("--output-dir", type=str, default="data/flight_events")
    parser.add_argument("--n-flights", type=int, default=5)
    args = parser.parse_args()

    run_date = datetime.strptime(args.run_date, "%Y-%m-%d")
    generate_flight_events(run_date, output_dir=args.output_dir, n_flights=args.n_flights)