package handler

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "strings"
    "time"

    "alfred/internal/repo"
    openai "github.com/sashabaranov/go-openai"
)

type QueryRequest struct {
    Query string `json:"query" validate:"required"`
    TopK  int    `json:"top_k"`
}

type QueryResponse struct {
    Answer    string     `json:"answer"`
    Citations []Citation `json:"citations"`
}

type Citation struct {
    ID      string `json:"id"`
    Excerpt string `json:"excerpt"`
}

type QueryHandler struct {
    repo   repo.EmbeddingRepo
    client OpenAIClient
}

func NewQueryHandler(repo repo.EmbeddingRepo, client OpenAIClient) *QueryHandler {
    return &QueryHandler{
        repo:   repo,
        client: client,
    }
}

func (h *QueryHandler) Handle(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        return
    }

    var req QueryRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    if req.Query == "" {
        http.Error(w, "Query is required", http.StatusBadRequest)
        return
    }

    if req.TopK == 0 {
        req.TopK = 4 // default
    }

    ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
    defer cancel()

    // Generate embedding for the query
    embResp, err := h.client.CreateEmbeddings(ctx, openai.EmbeddingRequest{
        Model: "text-embedding-3-small",
        Input: []string{req.Query},
    })
    if err != nil {
        http.Error(w, "Failed to generate query embedding", http.StatusInternalServerError)
        return
    }

    // Convert to our embedding type
    queryEmb := make(repo.Embedding, len(embResp.Data[0].Embedding))
    for i, v := range embResp.Data[0].Embedding {
        queryEmb[i] = float32(v)
    }

    // Search for similar documents
    hits, err := h.repo.Search(ctx, queryEmb, req.TopK)
    if err != nil {
        http.Error(w, "Failed to search documents", http.StatusInternalServerError)
        return
    }

    // Generate answer using GPT with citations
    answer, citations := h.generateAnswer(ctx, req.Query, hits)

    resp := QueryResponse{
        Answer:    answer,
        Citations: citations,
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(resp)
}

func (h *QueryHandler) generateAnswer(ctx context.Context, query string, hits []repo.SearchHit) (string, []Citation) {
    if len(hits) == 0 {
        return "No relevant documents found.", []Citation{}
    }

    // Build context from search hits
    var context strings.Builder
    citations := make([]Citation, 0, len(hits))

    for i, hit := range hits {
        context.WriteString(fmt.Sprintf("[%d] %s\n\n", i+1, hit.Excerpt))
        citations = append(citations, Citation{
            ID:      hit.ID,
            Excerpt: hit.Excerpt,
        })
    }

    // Generate answer with GPT
    prompt := fmt.Sprintf(`Based on the following context, answer the question. Use [^N] notation to cite sources.

Context:
%s

Question: %s

Answer:`, context.String(), query)

    resp, err := h.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
        Model: "gpt-3.5-turbo",
        Messages: []openai.ChatCompletionMessage{
            {Role: "system", Content: "You are a helpful assistant that answers questions based on provided context. Always cite your sources using [^N] notation."},
            {Role: "user", Content: prompt},
        },
        Temperature: 0.7,
        MaxTokens:   500,
    })

    if err != nil {
        return "Failed to generate answer.", citations
    }

    if len(resp.Choices) > 0 {
        return resp.Choices[0].Message.Content, citations
    }

    return "No answer generated.", citations
}
