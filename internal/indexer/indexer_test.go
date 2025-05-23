package indexer

import (
    "context"
    "testing"

    "alfred/internal/repo"
    openai "github.com/sashabaranov/go-openai"
)

type fakeRepo struct{ hits int }

func (f *fakeRepo) UpsertEmbeddings(_ context.Context, docs []repo.DocWithEmbedding) error {
    f.hits += len(docs)
    return nil
}
func (f *fakeRepo) Search(_ context.Context, _ repo.Embedding, _ int) ([]repo.SearchHit, error) {
    return nil, nil
}

func TestIndexer_Run(t *testing.T) {
    fp := []string{"../../testdata/docs/a.txt", "../../testdata/docs/b.txt"}
    rep := &fakeRepo{}
    ix, err := New(Config{
        ModelName: "fake",
        BatchSize: 1,
        Repo:      rep,
        Client:    &openaiClientStub{},
    })
    if err \!= nil {
        t.Fatal(err)
    }
    if err := ix.Run(context.Background(), fp); err \!= nil {
        t.Fatal(err)
    }
    if rep.hits \!= 2 {
        t.Fatalf("expected 2 upserts, got %d", rep.hits)
    }
}

/* openaiClientStub implements just enough for test */
type openaiClientStub struct{}

func (s *openaiClientStub) CreateEmbeddings(_ context.Context, _ openai.EmbeddingRequest) (openai.EmbeddingResponse, error) {
    return openai.EmbeddingResponse{
        Data: []openai.Embedding{{
            Embedding: make([]float64, 1536), // zeros
        }},
    }, nil
}
