-- Social Intelligence Database Schema
-- This schema defines the tables and views for niche analysis and scoring

-- Features table to store niche data and scoring metrics
CREATE TABLE IF NOT EXISTS features (
  niche_id       BIGSERIAL PRIMARY KEY,
  phrase         TEXT UNIQUE,
  demand_score   NUMERIC(5,4),
  monetise_score NUMERIC(5,4),
  supply_score   NUMERIC(5,4),
  opportunity    NUMERIC(6,5),
  updated_at     TIMESTAMPTZ DEFAULT now()
);

-- Create index on phrase for fast lookups
CREATE INDEX IF NOT EXISTS features_phrase_idx ON features(phrase);

-- Create index on opportunity for fast sorting
CREATE INDEX IF NOT EXISTS features_opportunity_idx ON features(opportunity DESC);

-- Create a materialized view for the top 50 niches updated daily
CREATE MATERIALIZED VIEW IF NOT EXISTS hot_niches_today AS
SELECT *
FROM   features
WHERE  updated_at > now() - interval '24 hours'
ORDER  BY opportunity DESC
LIMIT  50;

-- Create index on the materialized view for faster access
CREATE INDEX IF NOT EXISTS hot_niches_today_opportunity_idx ON hot_niches_today(opportunity DESC);

-- Add some sample data for testing
-- This can be removed in production
INSERT INTO features (phrase, demand_score, monetise_score, supply_score, opportunity)
VALUES
  ('Financial Literacy Shorts', 0.8750, 0.9200, 0.6500, 1.2346),
  ('DIY Home Improvement', 0.6230, 0.7800, 0.5500, 0.8829)
ON CONFLICT (phrase) DO NOTHING;
