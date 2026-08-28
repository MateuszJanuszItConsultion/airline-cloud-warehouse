CREATE TABLE IF NOT EXISTS airline_cloud_warehouse.bronze.currency_rates_raw (
  currency_code STRING COMMENT 'ISO currency code (e.g. EUR, GBP)',
  base_currency STRING COMMENT 'Base currency the rate is quoted against',
  rate_to_base DOUBLE COMMENT 'Exchange rate: 1 unit of base_currency = rate_to_base units of currency_code',
  rate_date STRING COMMENT 'Date the rate was published by the source (ECB via Frankfurter API)',
  _ingested_at TIMESTAMP,
  _source_file STRING
)
USING DELTA
COMMENT 'Raw daily currency exchange rates fetched from Frankfurter API (ECB reference rates)';