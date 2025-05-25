-- Model Registry Database Initialization
CREATE DATABASE IF NOT EXISTS model_registry;

\c model_registry;

-- Models table
CREATE TABLE IF NOT EXISTS models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL,
    provider VARCHAR(100),
    model_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Model metadata table
CREATE TABLE IF NOT EXISTS model_metadata (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES models(id),
    key VARCHAR(255) NOT NULL,
    value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_models_name ON models(name);
CREATE INDEX idx_models_provider ON models(provider);
CREATE INDEX idx_model_metadata_model_id ON model_metadata(model_id);
