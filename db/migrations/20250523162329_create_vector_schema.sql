-- +goose Up
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS documents (
    id        UUID PRIMARY KEY,
    content   TEXT NOT NULL,
    embedding vector(1536) NOT NULL,
    metadata  JSONB DEFAULT '{}'::jsonb,
    ts        tsvector GENERATED ALWAYS AS (to_tsvector('english', content)) STORED
);

-- 200-list IVFFLAT (cosine); tweak list count if ≠ 1536 dims or > 1M rows
CREATE INDEX IF NOT EXISTS documents_embedding_idx
    ON documents USING ivfflat (embedding vector_cosine_ops) WITH (lists = 200);

-- Full-text search
CREATE INDEX IF NOT EXISTS documents_ts_idx
    ON documents USING gin(ts);

-- +goose Down
DROP INDEX IF EXISTS documents_ts_idx;
DROP INDEX IF EXISTS documents_embedding_idx;
DROP TABLE  IF EXISTS documents;
DROP EXTENSION IF EXISTS vector;
