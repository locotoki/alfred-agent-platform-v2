package repo

import (
    "context"
    "fmt"

    "github.com/jackc/pgx/v5/pgxpool"
)

// PGRepo implements EmbeddingRepo backed by PostgreSQL + pgvector
type PGRepo struct {
    pool *pgxpool.Pool
}

// NewPGRepo creates a new PostgreSQL-backed embedding repository
func NewPGRepo(pool *pgxpool.Pool) *PGRepo {
    return &PGRepo{pool: pool}
}

// UpsertEmbeddings batch inserts/updates documents with embeddings
func (r *PGRepo) UpsertEmbeddings(ctx context.Context, docs []DocWithEmbedding) error {
    // Start a transaction for batch insert
    tx, err := r.pool.Begin(ctx)
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }
    defer tx.Rollback(ctx)

    // Prepare the upsert statement
    stmt := `
        INSERT INTO documents (id, content, embedding, metadata)
        VALUES ($1::uuid, $2, $3, $4)
        ON CONFLICT (id) DO UPDATE SET
            content = EXCLUDED.content,
            embedding = EXCLUDED.embedding,
            metadata = EXCLUDED.metadata
    `

    for _, doc := range docs {
        _, err := tx.Exec(ctx, stmt, doc.ID, doc.Content, doc.Embedding, doc.Metadata)
        if err != nil {
            return fmt.Errorf("upsert doc %s: %w", doc.ID, err)
        }
    }

    return tx.Commit(ctx)
}

// Search performs cosine similarity search on embeddings
func (r *PGRepo) Search(ctx context.Context, query Embedding, topK int) ([]SearchHit, error) {
    stmt := `
        SELECT id, content, 1 - (embedding <=> $1) as score
        FROM documents
        ORDER BY embedding <=> $1
        LIMIT $2
    `

    rows, err := r.pool.Query(ctx, stmt, query, topK)
    if err != nil {
        return nil, fmt.Errorf("search query: %w", err)
    }
    defer rows.Close()

    var hits []SearchHit
    for rows.Next() {
        var hit SearchHit
        var content string
        if err := rows.Scan(&hit.ID, &content, &hit.Score); err != nil {
            return nil, fmt.Errorf("scan row: %w", err)
        }

        // Create excerpt (first 200 chars)
        if len(content) > 200 {
            hit.Excerpt = content[:200] + "..."
        } else {
            hit.Excerpt = content
        }

        hits = append(hits, hit)
    }

    return hits, rows.Err()
}
