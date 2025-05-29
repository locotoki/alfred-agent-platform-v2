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

func TestQueryHandler_EmptyResults(t *testing.T) {
    // Mock repo that returns empty results
    mockRepo := &mockRepo{
        searchFunc: func(ctx context.Context, query repo.Embedding, topK int) ([]repo.SearchHit, error) {
            return []repo.SearchHit{}, nil
        },
    }

    // Mock OpenAI client
    mockClient := &mockOpenAIClient{}

    handler := &QueryHandler{
        repo:   mockRepo,
        client: mockClient,
    }

    req := QueryRequest{Query: "no results query", TopK: 5}
    body, _ := json.Marshal(req)
    r := httptest.NewRequest(http.MethodPost, "/v1/query", bytes.NewReader(body))
    w := httptest.NewRecorder()

    handler.Handle(w, r)

    if w.Code != http.StatusOK {
        t.Errorf("expected status 200, got %d", w.Code)
    }

    var resp QueryResponse
    if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
        t.Fatalf("failed to decode response: %v", err)
    }

    if resp.Answer != "No relevant documents found." {
        t.Errorf("expected empty result message, got: %s", resp.Answer)
    }

    if len(resp.Citations) != 0 {
        t.Errorf("expected no citations, got %d", len(resp.Citations))
    }
}
