import pandas as pd
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SEEDS_PATH = PROJECT_ROOT / "dbt_project" / "airline_warehouse" / "seeds"


def load_airport_codes(base_path: Path = SEEDS_PATH) -> list[str]:
    df = pd.read_csv(base_path / "airports.csv")
    return df["airport_code"].tolist()

def load_carriers(base_path: Path = SEEDS_PATH) -> list[str]:
    df = pd.read_csv(base_path / "carriers.csv")
    return df["carrier_code"].tolist()

def load_tail_numbers(base_path: Path = SEEDS_PATH) -> list[str]:
    df = pd.read_csv(base_path / "aircraft.csv")
    return df["tail_number"].tolist()