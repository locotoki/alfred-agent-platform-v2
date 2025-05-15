# Database Health Check Drivers

This package provides a standardized interface for database health checking across the Alfred Agent Platform v2.

## Overview

The database health check drivers provide:

- Standardized health status reporting (Up, Down, Degraded)
- Consistent metrics for monitoring database performance
- Connection pool management
- Read/write testing for comprehensive health assessment
- Prometheus integration with standard metrics format

## Usage

```go
package main

import (
    "context"
    "log"
    "time"
    
    "github.com/locotoki/alfred-agent-platform-v2/internal/db"
)

func main() {
    // Create a database driver with default configuration
    cfg := db.DefaultConfig()
    cfg.DSN = "postgres://user:password@localhost:5432/dbname"
    
    driver, err := db.NewDriver(cfg)
    if err != nil {
        log.Fatalf("Failed to create driver: %v", err)
    }
    
    // Connect to the database
    ctx := context.Background()
    if err := driver.Connect(ctx); err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer driver.Close()
    
    // Check database health
    if err := driver.Ping(ctx); err != nil {
        log.Printf("Ping failed: %v", err)
    }
    
    // Perform read/write test
    if err := driver.CheckReadWrite(ctx); err != nil {
        log.Printf("Read/write test failed: %v", err)
    }
    
    // Get database status
    status := driver.Status()
    log.Printf("Database status: %s", status)
    
    // Get metrics for Prometheus
    metrics := driver.Metrics()
    for name, value := range metrics {
        log.Printf("%s: %f", name, value)
    }
}
```

## Available Drivers

- PostgreSQL (highest priority, fully implemented)
- MySQL (placeholder)
- SQLite (placeholder)
- MSSQL (placeholder)

## Metrics

Each driver exports these metrics:

- `service_health`: Overall service health (1.0 = Up, 0.5 = Degraded, 0.0 = Down)
- `db_connection_success`: Connection success (1 = Success, 0 = Failure)
- `db_ping_success`: Ping success (1 = Success, 0 = Failure)
- `db_read_success`: Read operation success (1 = Success, 0 = Failure)
- `db_write_success`: Write operation success (1 = Success, 0 = Failure)
- `db_connection_latency_seconds`: Connection latency in seconds
- `db_ping_latency_seconds`: Ping latency in seconds
- `db_read_latency_seconds`: Read operation latency in seconds
- `db_write_latency_seconds`: Write operation latency in seconds

## Integration

These drivers are designed to be used with the healthcheck binary:

```go
// In healthcheck main.go
driver, _ := db.NewDriver(db.Config{
    DSN: os.Getenv("DATABASE_URL"),
    ...
})

// Export service_health metric for Prometheus
prometheus.MustRegister(prometheus.NewGaugeFunc(
    prometheus.GaugeOpts{
        Name: "service_health",
        Help: "Indicates whether the service is healthy (1), degraded (0.5), or unhealthy (0)",
    },
    func() float64 {
        metrics := driver.Metrics()
        return metrics["service_health"]
    },
))
```

## References

- [DB_PROBE_DESIGN.md](../../docs/phase5/DB_PROBE_DESIGN.md)
- [README-PHASE5-WORKFLOWS.md](../../README-PHASE5-WORKFLOWS.md)
- [Phase 5 Tracking Issue #33](https://github.com/locotoki/alfred-agent-platform-v2/issues/33)