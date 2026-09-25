import argparse
import json
import logging
import os
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from confluent_kafka import Producer

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ingestion.reference_data import load_tail_numbers

TOPIC = "aircraft-telemetry"

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def delivery_report(err, msg) -> None:
    if err is not None:
        logger.error("Delivery failed for key=%s: %s", msg.key(), err)
    else:
        logger.info("Delivered key=%s partition=%s offset=%s", msg.key().decode(), msg.partition(), msg.offset())


def build_producer() -> Producer:
    return Producer(
        {
            "bootstrap.servers": os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
            "acks": "all",
            "enable.idempotence": True,
            "partitioner": "murmur2_random",
        }
    )


def initial_state(tail_number: str) -> dict:
    return {
        "tail_number": tail_number,
        "latitude": random.uniform(30.0, 45.0),
        "longitude": random.uniform(-120.0, -75.0),
        "altitude_m": 0.0,
        "velocity_ms": random.uniform(70.0, 90.0),
        "heading_deg": random.uniform(0.0, 360.0),
    }


def advance(state: dict) -> dict:
    state["altitude_m"] = min(state["altitude_m"] + random.uniform(300.0, 800.0), 11000.0)
    state["velocity_ms"] = min(state["velocity_ms"] + random.uniform(5.0, 20.0), 250.0)
    state["latitude"] += random.uniform(-0.05, 0.05)
    state["longitude"] += random.uniform(-0.05, 0.05)
    return state


def produce_telemetry(n_aircraft: int = 5, n_ticks: int = 5, tick_seconds: float = 1.0) -> None:
    producer = build_producer()

    metadata = producer.list_topics(TOPIC, timeout=5)
    topic_metadata = metadata.topics[TOPIC]
    if topic_metadata.error is not None:
        raise RuntimeError(f"Topic '{TOPIC}' is not available: {topic_metadata.error}")

    fleet = random.sample(load_tail_numbers(), n_aircraft)
    states = {tail: initial_state(tail) for tail in fleet}

    for tick in range(n_ticks):
        for tail, state in states.items():
            event = {**advance(state), "tick": tick, "event_timestamp": datetime.now(timezone.utc).isoformat()}
            producer.produce(TOPIC, key=tail, value=json.dumps(event), callback=delivery_report)
        producer.poll(0)
        time.sleep(tick_seconds)

    remaining = producer.flush(10)
    if remaining > 0:
        raise RuntimeError(f"{remaining} messages were not delivered before timeout")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--n-aircraft", type=int, default=5)
    parser.add_argument("--n-ticks", type=int, default=5)
    parser.add_argument("--tick-seconds", type=float, default=1.0)
    args = parser.parse_args()

    produce_telemetry(args.n_aircraft, args.n_ticks, args.tick_seconds)