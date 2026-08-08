import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Ustawienie ziarna dla powtarzalności wyników
np.random.seed(42)
n_rows = 500

# Generowanie dat z jednego tygodnia
start_date = datetime(2026, 1, 1)
dates = [start_date + timedelta(days=int(i)) for i in np.random.randint(0, 7, size=n_rows)]

# Przykładowe linie lotnicze (OP_CARRIER) i lotniska (ORIGIN / DEST)
carriers = ['AA', 'DL', 'UA', 'WN', 'B6']
airports = ['JFK', 'LAX', 'ORD', 'DFW', 'DEN', 'SFO', 'ATL', 'MIA']

origins = np.random.choice(airports, size=n_rows)
# Upewniamy się, że DEST != ORIGIN
destinations = [np.random.choice([a for a in airports if a != o]) for o in origins]

# Opóźnienia i odwołania
dep_delays = np.random.normal(loc=5, scale=15, size=n_rows).round(1)
arr_delays = dep_delays + np.random.normal(loc=0, scale=10, size=n_rows).round(1)

# CANCELLED (1 - odwołany, 0 - wykonany) - ok 2% odwołanych lotów
cancelled = np.random.choice([0, 1], size=n_rows, p=[0.98, 0.02])

# Dla odwołanych lotów opóźnienia powinny być NaN/None
dep_delays = [None if c == 1 else d for d, c in zip(dep_delays, cancelled)]
arr_delays = [None if c == 1 else a for a, c in zip(arr_delays, cancelled)]

# Utworzenie DataFrame
df = pd.DataFrame({
    'FL_DATE': [d.strftime('%Y-%m-%d') for d in dates],
    'OP_CARRIER': np.random.choice(carriers, size=n_rows),
    'ORIGIN': origins,
    'DEST': destinations,
    'DEP_DELAY': dep_delays,
    'ARR_DELAY': arr_delays,
    'CANCELLED': cancelled
})

# Zapis do pliku
df.to_csv('C:\\DATA_ENGINEER\\airline-cloud-warehouse\\data\\sample_flights.csv', index=False)
print("Wygenerowano bts_sample_500.csv z 500 wierszami.")