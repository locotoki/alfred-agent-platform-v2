package handler

import (
    "context"
    openai "github.com/sashabaranov/go-openai"
)

// OpenAIClient interface wraps the OpenAI client methods we need
type OpenAIClient interface {
    CreateEmbeddings(ctx context.Context, request openai.EmbeddingRequest) (openai.EmbeddingResponse, error)
    CreateChatCompletion(ctx context.Context, request openai.ChatCompletionRequest) (openai.ChatCompletionResponse, error)
}
