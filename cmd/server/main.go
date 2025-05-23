package main

import (
    "context"
    "log"
    "net/http"
    "os"

    "alfred/internal/handler"
    "alfred/internal/repo"
    "github.com/jackc/pgx/v5/pgxpool"
    openai "github.com/sashabaranov/go-openai"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
    ctx := context.Background()

    // Database connection
    pool, err := pgxpool.New(ctx, os.Getenv("POSTGRES_DSN"))
    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }
    defer pool.Close()

    // Create repository
    embeddingRepo := repo.NewPGRepo(pool)

    // Create OpenAI client
    openaiClient := openai.NewClient(os.Getenv("OPENAI_API_KEY"))

    // Create handler
    queryHandler := handler.NewQueryHandler(embeddingRepo, openaiClient)

    // Setup routes
    http.HandleFunc("/v1/query", queryHandler.Handle)
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
    })
    http.Handle("/metrics", promhttp.Handler())

    // Start server
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Starting server on port %s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Fatal("Server failed:", err)
    }
}
