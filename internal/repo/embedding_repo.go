package repo

import "context"

// EmbeddingRepo defines the minimal contract required by agent-core (ADR-012).
type EmbeddingRepo interface {
    UpsertEmbeddings(ctx context.Context, docs []DocWithEmbedding) error
    Search(ctx context.Context, query Embedding, topK int) ([]SearchHit, error)
}

// ---- Domain types (temporary stubs; refine later) -----
type Embedding []float32

type DocWithEmbedding struct {
    ID        string
    Content   string
    Embedding Embedding
    Metadata  map[string]any
}

type SearchHit struct {
    ID      string
    Score   float32
    Excerpt string
}
