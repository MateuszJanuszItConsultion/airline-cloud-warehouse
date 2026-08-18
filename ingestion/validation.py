import great_expectations as gx
import pandas as pd

from ingestion.reference_data import load_airport_codes, load_carriers

AIRPORTS = load_airport_codes()
CARRIERS = load_carriers()
OPERATIONAL_STATUS = ['Active', 'Maintenance', 'Retired']

def validate_flights(df: pd.DataFrame) -> None:
    context = gx.get_context(mode="ephemeral")
    data_source = context.data_sources.add_pandas("flights_validation")
    data_asset = data_source.add_dataframe_asset(name="flights")
    batch_definition = data_asset.add_batch_definition_whole_dataframe("flights_batch")
    batch = batch_definition.get_batch(batch_parameters={"dataframe": df})

    suite = gx.ExpectationSuite(name="flights_suite")

    expectations = [
        gx.expectations.ExpectColumnValuesToNotBeNull(column="FL_DATE"),
        gx.expectations.ExpectColumnValuesToNotBeNull(column="OP_CARRIER"),
        gx.expectations.ExpectColumnValuesToBeInSet(column="OP_CARRIER", value_set=CARRIERS),
        gx.expectations.ExpectColumnValuesToNotBeNull(column="OP_FL_NUM"),
        gx.expectations.ExpectColumnValuesToBeBetween(column="OP_FL_NUM", min_value=100, max_value=9999),
        gx.expectations.ExpectColumnValuesToNotBeNull(column="ORIGIN"),
        gx.expectations.ExpectColumnValuesToBeInSet(column="ORIGIN", value_set=AIRPORTS),
        gx.expectations.ExpectColumnValuesToNotBeNull(column="DEST"),
        gx.expectations.ExpectColumnValuesToBeInSet(column="DEST", value_set=AIRPORTS),
        gx.expectations.ExpectColumnValuesToBeInSet(column="CANCELLED", value_set=[0, 1]),
        gx.expectations.ExpectColumnValuesToBeBetween(column="DEP_DELAY", min_value=-60, max_value=500),
    ]

    for e in expectations:
        suite.add_expectation(e)

    result = batch.validate(suite)

    if not result.success:
        raise ValueError(f"Data validation failed for flights data:\n{result}")

    print(f"Validation passed: {len(expectations)} expectations checked on {len(df)} rows.")

def validate_weather(df: pd.DataFrame) -> None:
    context = gx.get_context(mode="ephemeral")
    data_source = context.data_sources.add_pandas("weather_validation")
    data_asset = data_source.add_dataframe_asset(name="weather")
    batch_definition = data_asset.add_batch_definition_whole_dataframe("weather_batch")
    batch = batch_definition.get_batch(batch_parameters={"dataframe": df})

    suite = gx.ExpectationSuite(name="weather_suite")

    expectations = [
        gx.expectations.ExpectColumnValuesToNotBeNull(column="OBS_DATE"),
        gx.expectations.ExpectColumnValuesToNotBeNull(column="AIRPORT_CODE"),
        gx.expectations.ExpectColumnValuesToBeInSet(column="AIRPORT_CODE", value_set=AIRPORTS),
        gx.expectations.ExpectColumnValuesToBeBetween(column="AVG_TEMP_C", min_value=-50, max_value=80),
        gx.expectations.ExpectColumnValuesToBeInSet(column="HAS_SEVERE_WEATHER", value_set=[0, 1]),
        gx.expectations.ExpectColumnValuesToBeBetween(column="PRECIPITATION_MM", min_value=0, max_value=None)
    ]

    for e in expectations:
        suite.add_expectation(e)

    result = batch.validate(suite)

    if not result.success:
        raise ValueError(f"Data validation failed for weather data:\n{result}")

    print(f"Validation passed: {len(expectations)} expectations checked on {len(df)} rows.")

def validate_aircraft_utilization(df: pd.DataFrame) -> None:

    validation_df = df.copy()
    validation_df["_expected_scheduled"] = (
        validation_df["COMPLETED_FLIGHT_COUNT"] + validation_df["CANCELLED_FLIGHT_COUNT"]
    )

    context = gx.get_context(mode="ephemeral")
    data_source = context.data_sources.add_pandas("aircraft_utilization_validation")
    data_asset = data_source.add_dataframe_asset(name="aircraft_utilization")
    batch_definition = data_asset.add_batch_definition_whole_dataframe("aircraft_utilization_batch")
    batch = batch_definition.get_batch(batch_parameters={"dataframe": validation_df})

    suite = gx.ExpectationSuite(name="aircraft_utilization_suite")

    expectations = [
        gx.expectations.ExpectColumnValuesToNotBeNull(column="FL_DATE"),
        gx.expectations.ExpectColumnValuesToNotBeNull(column="AIRCRAFT_KEY"),
        gx.expectations.ExpectColumnValuesToBeInSet(column="AIRPORT_CODE", value_set=AIRPORTS),
        gx.expectations.ExpectColumnValuesToBeInSet(column="OPERATIONAL_STATUS", value_set=OPERATIONAL_STATUS),
        gx.expectations.ExpectColumnPairValuesAToBeGreaterThanB(
            column_A="SCHEDULED_FLIGHT_COUNT", column_B="COMPLETED_FLIGHT_COUNT", or_equal=True
        ),
        gx.expectations.ExpectColumnPairValuesAToBeGreaterThanB(
            column_A="SCHEDULED_FLIGHT_COUNT", column_B="CANCELLED_FLIGHT_COUNT", or_equal=True
        ),
        gx.expectations.ExpectColumnPairValuesToBeEqual(
            column_A="SCHEDULED_FLIGHT_COUNT", column_B="_expected_scheduled"
        ),
    ]

    for e in expectations:
        suite.add_expectation(e)

    result = batch.validate(suite)

    if not result.success:
        raise ValueError(f"Data validation failed for aircraft utilization data:\n{result}")

    print(f"Validation passed: {len(expectations)} expectations checked on {len(df)} rows.")