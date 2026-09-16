import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd
import requests

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

TOKEN_URL = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token"
STATES_URL = "https://opensky-network.org/api/states/all"

# Bounding box covering the continental US, matching dim_airport's seeded locations
BBOX = {"lamin": 24.5, "lamax": 49.5, "lomin": -125.0, "lomax": -66.5}

STATE_VECTOR_COLUMNS = [
    "icao24", "callsign", "origin_country", "time_position", "last_contact",
    "longitude", "latitude", "baro_altitude", "on_ground", "velocity",
    "true_track", "vertical_rate", "sensors", "geo_altitude", "squawk",
    "spi", "position_source",
]


def get_access_token() -> str:
    client_id = os.environ["OPENSKY_CLIENT_ID"]
    client_secret = os.environ["OPENSKY_CLIENT_SECRET"]

    response = requests.post(
        TOKEN_URL,
        data={
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
        },
        timeout=10,
    )
    response.raise_for_status()
    return response.json()["access_token"]


def fetch_opensky_states(run_date: datetime, output_dir: str = "data/opensky") -> str:
    token = get_access_token()

    response = requests.get(
        STATES_URL,
        headers={"Authorization": f"Bearer {token}"},
        params=BBOX,
        timeout=15,
    )
    response.raise_for_status()
    data = response.json()

    states = data.get("states") or []
    rows = [dict(zip(STATE_VECTOR_COLUMNS, state)) for state in states]
    df = pd.DataFrame(rows, columns=STATE_VECTOR_COLUMNS)
    df["snapshot_time"] = data["time"]

    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"opensky_states_{run_date:%Y%m%d_%H%M%S}.json")
    df.to_json(output_path, orient="records", lines=True)

    print(f"Fetched {len(rows)} aircraft states for bbox at {data['time']} -> {output_path}")
    return output_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", type=str, required=True)
    parser.add_argument("--output-dir", type=str, default="data/opensky")
    args = parser.parse_args()

    run_date = datetime.strptime(args.run_date, "%Y-%m-%d %H:%M:%S")
    fetch_opensky_states(run_date, output_dir=args.output_dir)