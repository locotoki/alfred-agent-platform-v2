# OpenTelemetry Tracing

The Alfred Healthcheck binary supports distributed tracing using OpenTelemetry. This allows you to correlate health check probe executions with other service traces, making it easier to identify the root cause of issues in your system.

## Enabling Tracing

Tracing is disabled by default to keep the binary lightweight for users who don't need this functionality. You can enable it with the `--trace-endpoint` flag:

```bash
healthcheck --trace-endpoint http://otel-collector.monitoring:4318
```

## Environment Variables

The following environment variables can be used to configure tracing:

| Variable | Description | Default |
|----------|-------------|---------|
| `TRACE_ENDPOINT` | OpenTelemetry collector OTLP/HTTP endpoint | (Overrides `--trace-endpoint` flag) |

## Span Information

When tracing is enabled, the health check creates a root span named `probe.<service>` with the following attributes:

- `service.name` - The service name (from `--service-name` flag)
- `result` - The result of the health check (`up`, `degraded`, or `down`)
- `error` - The error message if the health check failed (only present on failure)

The probe execution is wrapped in a single span, making it easy to correlate with other spans in your system.

## Integration with Grafana Tempo and Jaeger

The OpenTelemetry exporter can send traces to any OTLP-compatible collector, including:

- Grafana Tempo
- Jaeger
- OpenTelemetry Collector

This allows SREs to correlate a degraded probe with upstream/downstream latency spikes in a single view.

## Example Integration

Here's how you might integrate tracing in a Docker Compose environment:

```yaml
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otel/config.yaml"]
    volumes:
      - ./otel-config.yaml:/etc/otel/config.yaml:ro
    ports:
      - "4318:4318"  # OTLP/HTTP

  database:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_USER: alfred
      POSTGRES_DB: alfred_db
    healthcheck:
      test: ["CMD", "/healthcheck", "--db-type", "postgres", "--db-dsn", "alfred:password@localhost:5432/alfred_db", "--once", "--trace-endpoint", "http://otel-collector:4318", "--service-name", "postgres"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

## Testing Tracing

You can test tracing with the `noop` probe, which doesn't require any actual database:

```bash
healthcheck --probe noop --trace-endpoint http://otel-collector:4318 --service-name test-service
```

This will emit a simple trace span with a successful result, allowing you to verify your tracing pipeline.
