import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from ingestion.reference_data import load_airport_codes, load_tail_numbers
from ingestion.validation import validate_aircraft_utilization

AIRCRAFT_KEYS = load_tail_numbers()
AIRPORTS = load_airport_codes()

# Default seat capacity for aircraft, used to calculate available seat kilometers (ASK)
DEFAULT_SEAT_CAPACITY = 180

def generate_aircraft_utilization(run_date: datetime, output_dir: str = "data"):
    # Setting a random seed based on the run_date to ensure reproducibility of the generated data
    np.random.seed(int(run_date.strftime("%Y%m%d")))

    rows = []
    for aircraft in AIRCRAFT_KEYS:
        airport = np.random.choice(AIRPORTS)
        
        # Statistical status of the aircraft for the given day
        operational_status = np.random.choice(['Active', 'Maintenance', 'Retired'], p=[0.8, 0.15, 0.05])
        
        # Aircraft that are inactive or retired do not have scheduled flights
        if operational_status in ['Maintenance', 'Retired']:
            is_scheduled_day = 0
            scheduled_flight_count = 0
            completed_flight_count = 0
            cancelled_flight_count = 0
            block_hours_minutes = 0.0
            flight_hours_minutes = 0.0
            total_distance_km = 0
            total_passengers_carried = 0
            available_seat_kilometers = 0
            revenue_passenger_kilometers = 0
        else:
            is_scheduled_day = int(np.random.choice([0, 1], p=[0.1, 0.9]))
            
            if is_scheduled_day == 0:
                scheduled_flight_count = 0
                completed_flight_count = 0
                cancelled_flight_count = 0
                block_hours_minutes = 0.0
                flight_hours_minutes = 0.0
                total_distance_km = 0
                total_passengers_carried = 0
                available_seat_kilometers = 0
                revenue_passenger_kilometers = 0
            else:
                # Number of scheduled flights during the day (from 1 to 5)
                scheduled_flight_count = int(np.random.choice([1, 2, 3, 4, 5], p=[0.15, 0.35, 0.30, 0.15, 0.05]))
                
                # We randomly select cancellations (e.g., about a 5% chance of cancelling a single flight)
                cancelled_flight_count = int(np.random.binomial(n=scheduled_flight_count, p=0.05))
                completed_flight_count = scheduled_flight_count - cancelled_flight_count
                
                if completed_flight_count > 0:
                    # On average ~1200 km per flight
                    total_distance_km = int(max(200, np.random.normal(loc=1200 * completed_flight_count, scale=250)))
                    
                    # Flight Hours scaled to completed flights
                    flight_hours_minutes = round(
                        float(max(0.5, np.random.normal(loc=2.0 * completed_flight_count, scale=0.4))), 2
                    )
                    
                    # Block Hours = flight time + ~30 min for ground operations per flight
                    block_hours_minutes = round(flight_hours_minutes + (completed_flight_count * 0.5), 2)
                    
                    # Load Factor e.g., 70% - 95%
                    load_factor = np.random.uniform(0.70, 0.95)
                    
                    total_seats = DEFAULT_SEAT_CAPACITY * completed_flight_count
                    total_passengers_carried = int(total_seats * load_factor)
                    
                    # ASK = Available Seats * Distance
                    available_seat_kilometers = int(total_seats * total_distance_km)
                    
                    # RPK = Revenue Passenger Kilometers = Occupied Seats (Passengers) * Distance
                    revenue_passenger_kilometers = int(total_passengers_carried * total_distance_km)
                else:
                    block_hours_minutes = 0.0
                    flight_hours_minutes = 0.0
                    total_distance_km = 0
                    total_passengers_carried = 0
                    available_seat_kilometers = 0
                    revenue_passenger_kilometers = 0

        # Creating a dictionary for the current aircraft's utilization data
        rows.append({
            'FL_DATE': run_date.strftime('%Y-%m-%d'),
            'AIRCRAFT_KEY': aircraft,
            'AIRPORT_CODE': airport,
            'OPERATIONAL_STATUS': operational_status,
            'IS_SCHEDULED_DAY': is_scheduled_day,
            'SCHEDULED_FLIGHT_COUNT': scheduled_flight_count,
            'COMPLETED_FLIGHT_COUNT': completed_flight_count,
            'CANCELLED_FLIGHT_COUNT': cancelled_flight_count,
            'BLOCK_HOURS': block_hours_minutes,
            'FLIGHT_HOURS': flight_hours_minutes,
            'TOTAL_DISTANCE_KM': total_distance_km,
            'TOTAL_PASSENGERS_CARRIED': total_passengers_carried,
            'AVAILABLE_SEAT_KILOMETERS': available_seat_kilometers,
            'REVENUE_PASSENGER_KILOMETERS': revenue_passenger_kilometers
        })

    # Creating the entire DataFrame at once from the list of dictionaries
    df = pd.DataFrame(rows)

    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"aircraft_utilization_{run_date:%Y%m%d}.parquet")
    validate_aircraft_utilization(df)
    df.to_parquet(output_path, index=False)
    print(f"Generated {len(df)} rows for date {run_date.date()} -> {output_path}")
    return output_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", type=str, required=True, help="YYYY-MM-DD")
    parser.add_argument("--output-dir", type=str, default="data")
    args = parser.parse_args()

    run_date = datetime.strptime(args.run_date, "%Y-%m-%d")
    generate_aircraft_utilization(run_date, output_dir=args.output_dir)