# Database Health Probe Design

This document outlines the implementation of standardized database health checks for the Alfred Agent Platform v2. These checks ensure consistent monitoring and reporting of database status across all services.

## Overview

The database health probe is designed to:

1. Test database connectivity
2. Verify database operations (read/write)
3. Report metrics on database health
4. Integrate with our standard healthcheck binary (v0.4.0)
5. Export Prometheus metrics on port 9091

## Database Probe Specifications

| Database   | DSN Format                            | Driver        | Test Table            | Priority | Status      |
|------------|---------------------------------------|---------------|------------------------|----------|-------------|
| PostgreSQL | postgres://user:pass@host:5432/dbname | pgx           | alfred_health_check   | 1        | Implemented |
| MySQL      | mysql://user:pass@tcp(host:3306)/db   | mysql         | alfred_health_check   | 2        | Implemented |
| SQLite     | file:db.sqlite?cache=shared&mode=rwc  | modernc.org/sqlite | alfred_health_check | 3        | Implemented |
| MSSQL      | sqlserver://user:pass@host:1433/db    | mssql         | dbo.alfred_health_check | 4      | Planned     |

### Common Interface

All database probes implement the following interface:

```go
// internal/db/driver.go

package db

import (
	"context"
	"time"
)

// Status represents the health status of a database
type Status string

const (
	StatusUp   Status = "up"
	StatusDown Status = "down"
	StatusDegraded Status = "degraded"
)

// Driver defines the common interface for database health checks
type Driver interface {
	// Connect establishes a connection to the database
	Connect(ctx context.Context) error

	// Ping verifies the database connection is still alive
	Ping(ctx context.Context) error

	// CheckReadWrite performs a read/write test on the health check table
	CheckReadWrite(ctx context.Context) error

	// Close closes the database connection
	Close() error

	// Status returns the current database status
	Status() Status

	// Metrics returns the database metrics
	Metrics() map[string]float64
}

// Config contains common configuration for database drivers
type Config struct {
	// DSN is the data source name for the database connection
	DSN string

	// ConnectTimeout is the maximum time allowed for connecting to the database
	ConnectTimeout time.Duration

	// PingTimeout is the maximum time allowed for ping operations
	PingTimeout time.Duration

	// ReadTimeout is the maximum time allowed for read operations
	ReadTimeout time.Duration

	// WriteTimeout is the maximum time allowed for write operations
	WriteTimeout time.Duration

	// TableCreationTimeout is the maximum time allowed for table creation
	TableCreationTimeout time.Duration

	// MaxRetries is the number of times to retry operations before giving up
	MaxRetries int

	// RetryInterval is the time to wait between retries
	RetryInterval time.Duration

	// CreateHealthTable determines whether to create the health check table if it doesn't exist
	CreateHealthTable bool

	// MaxOpenConns sets the maximum number of open connections to the database
	MaxOpenConns int

	// MaxIdleConns sets the maximum number of connections in the idle connection pool
	MaxIdleConns int

	// ConnMaxLifetime sets the maximum amount of time a connection may be reused
	ConnMaxLifetime time.Duration

	// ConnMaxIdleTime sets the maximum amount of time a connection may be idle
	ConnMaxIdleTime time.Duration
}

// NewDriver creates a new database driver based on the DSN scheme
func NewDriver(cfg Config) (Driver, error) {
	// Determine driver type from DSN
	switch {
	case strings.HasPrefix(cfg.DSN, "postgres://"):
		return newPostgresDriver(cfg), nil
	case strings.HasPrefix(cfg.DSN, "mysql://"):
		return newMySQLDriver(cfg), nil
	case strings.HasPrefix(cfg.DSN, "file:"):
		return newSQLiteDriver(cfg), nil
	case strings.HasPrefix(cfg.DSN, "sqlserver://"):
		return newMSSQLDriver(cfg), nil
	default:
		return nil, fmt.Errorf("unsupported database scheme in DSN: %s", cfg.DSN)
	}
}
```

## Driver Implementations

### PostgreSQL Implementation

The PostgreSQL driver uses the github.com/lib/pq package and handles PostgreSQL-specific operations including table creation, upsert syntax, and connection management.

### MySQL Implementation

The MySQL driver uses the github.com/go-sql-driver/mysql package and provides MySQL-specific implementations for all interface methods.

### SQLite Implementation

The SQLite driver uses the modernc.org/sqlite package, which is a pure Go implementation that doesn't require CGO. This allows for simpler cross-compilation and statically linked binaries. Key features of the SQLite implementation include:

- Optimized for SQLite's single-writer/multiple-reader model
- Limited connection pool size to prevent "database is locked" errors
- Support for WAL journaling mode for improved concurrency
- SQLite-specific pragma settings for foreign keys
- URI query parameter support for SQLite-specific options

```go
// internal/db/sqlite.go

package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "modernc.org/sqlite" // Pure Go SQLite driver (CGO-free)
)

// sqliteDriver implements the Driver interface for SQLite databases
type sqliteDriver struct {
	cfg     Config
	db      *sql.DB
	status  Status
	metrics map[string]float64
}

// newSQLiteDriver creates a new SQLite driver
func newSQLiteDriver(cfg Config) Driver {
	return &sqliteDriver{
		cfg:     cfg,
		status:  StatusDown,
		metrics: make(map[string]float64),
	}
}

// Connect establishes a connection to the SQLite database
func (d *sqliteDriver) Connect(ctx context.Context) error {
	startTime := time.Now()

	// Open database connection
	db, err := sql.Open("sqlite", d.cfg.DSN)
	if err != nil {
		d.status = StatusDown
		d.metrics["db_connection_success"] = 0
		d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
		return fmt.Errorf("failed to open database connection: %w", err)
	}

	// Configure connection pool - SQLite optimized
	maxConn := d.cfg.MaxOpenConns
	if maxConn > 10 {
		maxConn = 10 // SQLite handles concurrency differently
	}
	db.SetMaxOpenConns(maxConn)
	db.SetMaxIdleConns(d.cfg.MaxIdleConns)
	db.SetConnMaxLifetime(d.cfg.ConnMaxLifetime)
	db.SetConnMaxIdleTime(d.cfg.ConnMaxIdleTime)

	// Test connection
	if err := db.PingContext(ctx); err != nil {
		d.status = StatusDown
		return fmt.Errorf("failed to ping database: %w", err)
	}

	// Create health check table if enabled
	if d.cfg.CreateHealthTable {
		if err := d.createHealthTable(ctx, db); err != nil {
			d.status = StatusDegraded
			return fmt.Errorf("failed to create health check table: %w", err)
		}
	}

	d.db = db
	d.status = StatusUp
	return nil
}

// Additional methods implementing the Driver interface
// ...
```

## Integration with Health Checks

The database drivers are integrated with the standard healthcheck binary:

```go
// cmd/healthcheck/main.go

// Example integration for database monitoring
func monitorDatabase(cfg Config) {
	var driver db.Driver
	var err error

	// Create driver based on provided DSN
	if cfg.PostgresDSN != "" {
		driver, err = db.NewDriver(db.Config{
			DSN:               cfg.PostgresDSN,
			ConnectTimeout:    5 * time.Second,
			ReadTimeout:       2 * time.Second,
			WriteTimeout:      2 * time.Second,
			CreateHealthTable: true,
		})
	} else if cfg.MySQLDSN != "" {
		driver, err = db.NewDriver(db.Config{
			DSN:               cfg.MySQLDSN,
			ConnectTimeout:    5 * time.Second,
			ReadTimeout:       2 * time.Second,
			WriteTimeout:      2 * time.Second,
			CreateHealthTable: true,
		})
	} else if cfg.SQLiteDSN != "" {
		driver, err = db.NewDriver(db.Config{
			DSN:               cfg.SQLiteDSN,
			ConnectTimeout:    5 * time.Second,
			ReadTimeout:       2 * time.Second,
			WriteTimeout:      2 * time.Second,
			CreateHealthTable: true,
		})
	} else {
		logger.Error("No database DSN provided")
		os.Exit(1)
	}

	if err != nil {
		logger.Error("Failed to create database driver", "error", err)
		os.Exit(1)
	}

	// Connect to database
	ctx := context.Background()
	if err := driver.Connect(ctx); err != nil {
		logger.Error("Failed to connect to database", "error", err)
		os.Exit(1)
	}

	// Start monitoring loop
	// ...
}
```

## Docker Integration

Database health checks are integrated into our Docker services using our standard pattern:

```dockerfile
# Example Dockerfile for database service
FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM postgres:14

# Copy healthcheck binary from builder
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# Expose database and metrics ports
EXPOSE 5432
EXPOSE 9091

# Use healthcheck wrapper to run service
CMD ["healthcheck", "--export-metrics", ":9091", "--postgres-dsn", "postgres://postgres:postgres@localhost:5432/postgres", "--", "docker-entrypoint.sh", "postgres"]
```

## Prometheus Metrics

The database health probe exports the following metrics:

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `service_health` | Gauge | 1.0=up, 0.5=degraded, 0.0=down | `service`, `instance` |
| `db_connection_success` | Gauge | Connection success (1=success, 0=failure) | `service`, `instance`, `db_name` |
| `db_ping_success` | Gauge | Ping success (1=success, 0=failure) | `service`, `instance`, `db_name` |
| `db_read_success` | Gauge | Read operation success (1=success, 0=failure) | `service`, `instance`, `db_name` |
| `db_write_success` | Gauge | Write operation success (1=success, 0=failure) | `service`, `instance`, `db_name` |
| `db_connection_latency_seconds` | Gauge | Database connection latency | `service`, `instance`, `db_name` |
| `db_ping_latency_seconds` | Gauge | Database ping latency | `service`, `instance`, `db_name` |
| `db_read_latency_seconds` | Gauge | Database read operation latency | `service`, `instance`, `db_name` |
| `db_write_latency_seconds` | Gauge | Database write operation latency | `service`, `instance`, `db_name` |
| `db_driver_type` | Gauge | Database driver type (1=Postgres, 2=MySQL, 3=SQLite, 4=MSSQL) | `service`, `instance`, `db_name` |

## Testing Strategy

We implement comprehensive testing for database health checks:

### Unit Tests

Using sqlmock to test database driver functions without real database connections.

### Integration Tests

Using real database connections to test the full functionality of each driver.

## Implementation Plan Progress

1. ✅ Create base database driver interface and factory method
2. ✅ Implement PostgreSQL driver as highest priority
3. ✅ Add unit tests with sqlmock for PostgreSQL
4. ✅ Configure integration tests for PostgreSQL
5. ✅ Implement MySQL driver
6. ✅ Add unit tests with sqlmock for MySQL
7. ✅ Configure integration tests for MySQL
8. ✅ Implement SQLite driver (for local development)
9. ✅ Add unit tests with sqlmock for SQLite
10. ✅ Configure integration tests for SQLite
11. ⬜ Implement MSSQL driver (if needed)
12. ⬜ Add unit tests with sqlmock for MSSQL
13. ⬜ Configure integration tests for MSSQL
14. ⬜ Integrate with healthcheck binary
15. ⬜ Update Dockerfile templates for database services
16. ⬜ Create Grafana dashboard for database health metrics

## Reference Implementation

See these example files for reference:

- [Database Driver Interface](../../internal/db/driver.go)
- [PostgreSQL Driver Implementation](../../internal/db/postgres.go)
- [MySQL Driver Implementation](../../internal/db/mysql.go)
- [SQLite Driver Implementation](../../internal/db/sqlite.go)
- [Prometheus Alert Rules](../../monitoring/prometheus/alerts/service_health.yml)
- [CLI Reference Documentation](./CLI_REFERENCE.md)

## GitHub Actions Workflows

The implementation is validated by dedicated GitHub Actions workflows:

- [Database Health Checks Workflow](../../.github/workflows/db-health-phase5.yml)
- [Monitoring Health Checks Workflow](../../.github/workflows/monitoring-health-phase5.yml)
- [Phase 5 Summary Workflow](../../.github/workflows/phase5-summary.yml)

## Alert Rules

The monitoring system includes database-specific alert rules for each database type:

```yaml
# SQLite-specific alert rules
- alert: SQLiteHealthCritical
  expr: service_health{db_driver_type="3"} == 0
  for: 30s
  labels:
    severity: critical
  annotations:
    summary: "SQLite database unhealthy for {{ $labels.service }}"
    description: "SQLite database used by {{ $labels.service }} is not operational for more than 30 seconds"
    dashboard_url: "https://grafana.alfred-platform.local/d/db-health?var-service={{ $labels.service }}&var-db_type=sqlite"

- alert: SQLiteHealthDegraded
  expr: service_health{db_driver_type="3"} == 0.5
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "SQLite database degraded for {{ $labels.service }}"
    description: "SQLite database used by {{ $labels.service }} is in degraded state for more than 2 minutes"
    dashboard_url: "https://grafana.alfred-platform.local/d/db-health?var-service={{ $labels.service }}&var-db_type=sqlite"
```

See the [service_health.yml](../../monitoring/prometheus/alerts/service_health.yml) file for a complete implementation of service health alert rules.

## Conclusion

This design provides a standardized approach to database health monitoring across our platform. By implementing common interfaces and leveraging our existing healthcheck infrastructure, we ensure consistent reporting and metrics collection for all database services.

The implementation prioritizes PostgreSQL as our primary database technology, with support for MySQL and SQLite, and planned support for MSSQL. The modular design allows for easy extension to additional database types in the future.

## Tracking

Implementation progress is tracked in [Phase 5 Progress Issue #33](https://github.com/locotoki/alfred-agent-platform-v2/issues/33). The status is automatically updated weekly by the Phase 5 Summary workflow.
