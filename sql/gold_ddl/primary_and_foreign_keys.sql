-- Informational constraints (not enforced by Databricks) added to support
-- automatic relationship modeling in BI tools (Power BI, Tableau) via JDBC/ODBC.
--
-- Order matters: primary keys on dimensions must exist before foreign keys
-- on facts can reference them.

-- Primary keys (dimensions) --------------------------------------------------

ALTER TABLE airline_cloud_warehouse.gold.dim_date ALTER COLUMN date_key SET NOT NULL;
ALTER TABLE airline_cloud_warehouse.gold.dim_date ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_key);

ALTER TABLE airline_cloud_warehouse.gold.dim_airport ALTER COLUMN airport_code SET NOT NULL;
ALTER TABLE airline_cloud_warehouse.gold.dim_airport ADD CONSTRAINT pk_dim_airport PRIMARY KEY (airport_code);

ALTER TABLE airline_cloud_warehouse.gold.dim_carrier ALTER COLUMN carrier_code SET NOT NULL;
ALTER TABLE airline_cloud_warehouse.gold.dim_carrier ADD CONSTRAINT pk_dim_carrier PRIMARY KEY (carrier_code);

ALTER TABLE airline_cloud_warehouse.gold.dim_aircraft ALTER COLUMN tail_number SET NOT NULL;
ALTER TABLE airline_cloud_warehouse.gold.dim_aircraft ADD CONSTRAINT pk_dim_aircraft PRIMARY KEY (tail_number);

-- Foreign keys (facts) --------------------------------------------------------

ALTER TABLE airline_cloud_warehouse.gold.fact_flight_performance ADD CONSTRAINT fk_ffp_date FOREIGN KEY (date_key) REFERENCES airline_cloud_warehouse.gold.dim_date;
ALTER TABLE airline_cloud_warehouse.gold.fact_flight_performance ADD CONSTRAINT fk_ffp_carrier FOREIGN KEY (carrier_code) REFERENCES airline_cloud_warehouse.gold.dim_carrier;
ALTER TABLE airline_cloud_warehouse.gold.fact_flight_performance ADD CONSTRAINT fk_ffp_origin FOREIGN KEY (origin_airport) REFERENCES airline_cloud_warehouse.gold.dim_airport;
ALTER TABLE airline_cloud_warehouse.gold.fact_flight_performance ADD CONSTRAINT fk_ffp_dest FOREIGN KEY (dest_airport) REFERENCES airline_cloud_warehouse.gold.dim_airport;

ALTER TABLE airline_cloud_warehouse.gold.fact_weather_observation ADD CONSTRAINT fk_fwo_date FOREIGN KEY (date_key) REFERENCES airline_cloud_warehouse.gold.dim_date;
ALTER TABLE airline_cloud_warehouse.gold.fact_weather_observation ADD CONSTRAINT fk_fwo_airport FOREIGN KEY (airport_code) REFERENCES airline_cloud_warehouse.gold.dim_airport;

ALTER TABLE airline_cloud_warehouse.gold.fact_aircraft_utilization ADD CONSTRAINT fk_fau_date FOREIGN KEY (date_key) REFERENCES airline_cloud_warehouse.gold.dim_date;
ALTER TABLE airline_cloud_warehouse.gold.fact_aircraft_utilization ADD CONSTRAINT fk_fau_aircraft FOREIGN KEY (aircraft_key) REFERENCES airline_cloud_warehouse.gold.dim_aircraft;
ALTER TABLE airline_cloud_warehouse.gold.fact_aircraft_utilization ADD CONSTRAINT fk_fau_airport FOREIGN KEY (airport_code) REFERENCES airline_cloud_warehouse.gold.dim_airport;