import json

from ingestion.produce_aircraft_telemetry import TOPIC, build_producer

BAD_RECORDS = [
    ("SP-LRA", json.dumps({"txt": 3222})),
    ("SP-LRA", "to nie jest json"),
    (
        "SP-LRA",
        json.dumps(
            {
                "tail_number": "N104NN",
                "latitude": 40.0,
                "longitude": -75.0,
                "altitude_m": 1000.0,
                "velocity_ms": 100.0,
                "heading_deg": 90.0,
                "tick": 0,
                "event_timestamp": "2026-09-26T20:00:00+00:00",
            }
        ),
    ),
]

if __name__ == "__main__":
    producer = build_producer()
    for key, value in BAD_RECORDS:
        producer.produce(TOPIC, key=key, value=value)
    remaining = producer.flush(10)
    if remaining > 0:
        raise RuntimeError(f"{remaining} messages were not delivered")
    print(f"Sent {len(BAD_RECORDS)} deliberately invalid records to '{TOPIC}'")