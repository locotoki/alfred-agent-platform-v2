CREATE EXTENSION IF NOT EXISTS pgvector;
-- sample table for spike
CREATE TABLE IF NOT EXISTS embeddings (
  id TEXT PRIMARY KEY,
  path TEXT,
  sha  TEXT,
  vec  vector(768)
);