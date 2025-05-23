package handler

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    // Total number of retrieval requests
    retrievalRequestsTotal = promauto.NewCounter(prometheus.CounterOpts{
        Name: "retrieval_requests_total",
        Help: "Total number of retrieval requests",
    })

    // Total number of retrieval errors by kind
    retrievalErrorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "retrieval_errors_total",
        Help: "Total number of retrieval errors",
    }, []string{"kind"})

    // Retrieval latency histogram in milliseconds
    retrievalLatencyMs = promauto.NewHistogram(prometheus.HistogramOpts{
        Name:    "retrieval_latency_ms",
        Help:    "Retrieval latency in milliseconds",
        Buckets: prometheus.ExponentialBuckets(10, 2, 10), // 10ms to ~10s
    })

    // OpenAI API tokens used (optional)
    openaiTokensTotal = promauto.NewCounter(prometheus.CounterOpts{
        Name: "openai_tokens_total",
        Help: "Total number of OpenAI tokens consumed",
    })
)
