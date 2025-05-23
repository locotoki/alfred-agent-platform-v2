package handler

import (
    "bytes"
    "context"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"

    "alfred/internal/repo"
    openai "github.com/sashabaranov/go-openai"
)

type mockRepo struct {
    searchFunc func(ctx context.Context, query repo.Embedding, topK int) ([]repo.SearchHit, error)
}

func (m *mockRepo) UpsertEmbeddings(ctx context.Context, docs []repo.DocWithEmbedding) error {
    return nil
}

func (m *mockRepo) Search(ctx context.Context, query repo.Embedding, topK int) ([]repo.SearchHit, error) {
    if m.searchFunc != nil {
        return m.searchFunc(ctx, query, topK)
    }
    return []repo.SearchHit{
        {ID: "doc1", Score: 0.95, Excerpt: "This is a test document about testing."},
        {ID: "doc2", Score: 0.85, Excerpt: "Another document with relevant content."},
    }, nil
}

type mockOpenAIClient struct{}

func (m *mockOpenAIClient) CreateEmbeddings(ctx context.Context, req openai.EmbeddingRequest) (openai.EmbeddingResponse, error) {
    return openai.EmbeddingResponse{
        Data: []openai.Embedding{
            {Embedding: make([]float64, 1536)}, // zeros for testing
        },
    }, nil
}

func (m *mockOpenAIClient) CreateChatCompletion(ctx context.Context, req openai.ChatCompletionRequest) (openai.ChatCompletionResponse, error) {
    return openai.ChatCompletionResponse{
        Choices: []openai.ChatCompletionChoice{
            {
                Message: openai.ChatCompletionMessage{
                    Content: "Based on the documents [^1], this is a test answer [^2].",
                },
            },
        },
    }, nil
}

func TestQueryHandler(t *testing.T) {
    tests := []struct {
        name       string
        request    QueryRequest
        wantStatus int
    }{
        {
            name:       "valid query",
            request:    QueryRequest{Query: "test query", TopK: 2},
            wantStatus: http.StatusOK,
        },
        {
            name:       "empty query",
            request:    QueryRequest{Query: "", TopK: 2},
            wantStatus: http.StatusBadRequest,
        },
        {
            name:       "default top_k",
            request:    QueryRequest{Query: "test query"},
            wantStatus: http.StatusOK,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            handler := &QueryHandler{
                repo:   &mockRepo{},
                client: &mockOpenAIClient{},
            }

            body, _ := json.Marshal(tt.request)
            req := httptest.NewRequest(http.MethodPost, "/v1/query", bytes.NewReader(body))
            w := httptest.NewRecorder()

            handler.Handle(w, req)

            if w.Code != tt.wantStatus {
                t.Errorf("got status %d, want %d", w.Code, tt.wantStatus)
            }

            if w.Code == http.StatusOK {
                var resp QueryResponse
                if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
                    t.Fatalf("failed to decode response: %v", err)
                }
                if resp.Answer == "" {
                    t.Error("expected non-empty answer")
                }
                if len(resp.Citations) == 0 {
                    t.Error("expected citations")
                }
            }
        })
    }
}
