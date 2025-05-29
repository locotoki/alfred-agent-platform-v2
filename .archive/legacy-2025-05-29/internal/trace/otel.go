package trace

import (
    "context"
    "log"
    "time"

    "go.opentelemetry.io/otel"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/sdk/resource"
    semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
    "go.opentelemetry.io/otel/trace"
)

// Init initializes OpenTelemetry with the given endpoint and service name.
// Returns a function to shutdown the tracer provider.
func Init(endpoint string, svc string) (func(context.Context) error, error) {
    exp, err := otlptracehttp.New(context.Background(),
        otlptracehttp.WithEndpoint(endpoint),
        otlptracehttp.WithInsecure())
    if err != nil {
        return nil, err
    }

    provider := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exp),
        sdktrace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceNameKey.String(svc),
        )),
    )
    otel.SetTracerProvider(provider)
    log.Printf("[otel] exporter up → %s", endpoint)
    return provider.Shutdown, nil
}

// StartSpan creates a new span and returns the updated context and a function to end the span.
func StartSpan(ctx context.Context, name string) (context.Context, func()) {
    tr := otel.Tracer("healthcheck")
    ctx, span := tr.Start(ctx, name)
    return ctx, func() { span.End() }
}

// AddAttribute adds an attribute to the current span in the context.
func AddAttribute(ctx context.Context, key string, value string) {
    span := trace.SpanFromContext(ctx)
    span.SetAttributes(attribute.String(key, value))
}
