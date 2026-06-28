-- sql/bronze/create_bronze_tables.sql

-- Create the bronze schema
CREATE SCHEMA IF NOT EXISTS bronze;

-- Raw flight states from OpenSky Network
CREATE TABLE IF NOT EXISTS bronze.raw_flight_states (
    id                  SERIAL PRIMARY KEY,
    batch_id            UUID NOT NULL,
    source              VARCHAR(20) NOT NULL CHECK (source IN ('api', 'synthetic')),
    extracted_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- OpenSky core fields (stored as raw text to preserve original values)
    icao24              TEXT,
    callsign            TEXT,
    origin_country      TEXT,
    time_position       BIGINT,       -- Unix timestamp
    last_contact        BIGINT,       -- Unix timestamp
    longitude           DOUBLE PRECISION,
    latitude            DOUBLE PRECISION,
    baro_altitude       DOUBLE PRECISION,
    on_ground           BOOLEAN,
    velocity            DOUBLE PRECISION,
    true_track          DOUBLE PRECISION,
    vertical_rate       DOUBLE PRECISION,
    geo_altitude        DOUBLE PRECISION,
    squawk              TEXT,
    spi                 BOOLEAN,
    position_source     INTEGER,

    -- Raw payload stored for reprocessing if schema changes
    raw_payload         JSONB NOT NULL
);

-- Index for fast batch lookups and deduplication
CREATE INDEX IF NOT EXISTS idx_raw_flight_states_batch_id
    ON bronze.raw_flight_states(batch_id);

CREATE INDEX IF NOT EXISTS idx_raw_flight_states_extracted_at
    ON bronze.raw_flight_states(extracted_at);

CREATE INDEX IF NOT EXISTS idx_raw_flight_states_icao24
    ON bronze.raw_flight_states(icao24);

-- Ingestion run log — tracks every pipeline execution
CREATE TABLE IF NOT EXISTS bronze.ingestion_log (
    id                  SERIAL PRIMARY KEY,
    batch_id            UUID NOT NULL UNIQUE,
    run_started_at      TIMESTAMPTZ NOT NULL,
    run_completed_at    TIMESTAMPTZ,
    source              VARCHAR(20) NOT NULL,
    records_extracted   INTEGER DEFAULT 0,
    records_loaded      INTEGER DEFAULT 0,
    status              VARCHAR(20) NOT NULL CHECK (status IN ('running', 'success', 'failed')),
    error_message       TEXT,
    api_response_time_ms INTEGER
);