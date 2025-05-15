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

| Database   | DSN Format                            | Driver        | Test Table            | Priority |
|------------|---------------------------------------|---------------|------------------------|----------|
| PostgreSQL | postgres://user:pass@host:5432/dbname | pgx           | _health_check         | 1        |
| MySQL      | mysql://user:pass@tcp(host:3306)/db   | mysql         | _health_check         | 2        |
| SQLite     | file:db.sqlite?cache=shared&mode=rwc  | sqlite3       | _health_check         | 3        |
| MSSQL      | sqlserver://user:pass@host:1433/db    | mssql         | dbo._health_check     | 4        |

### Common Interface

All database probes will implement the following interface:

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
	DSN              string
	ConnectTimeout   time.Duration
	ReadTimeout      time.Duration
	WriteTimeout     time.Duration
	MaxRetries       int
	RetryInterval    time.Duration
	CreateHealthTable bool
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

## PostgreSQL Implementation

### Driver Implementation

```go
// internal/db/postgres.go

package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"
	
	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/stdlib"
)

type postgresDriver struct {
	cfg    Config
	db     *sql.DB
	status Status
	metrics map[string]float64
}

func newPostgresDriver(cfg Config) Driver {
	return &postgresDriver{
		cfg:     cfg,
		status:  StatusDown,
		metrics: make(map[string]float64),
	}
}

func (d *postgresDriver) Connect(ctx context.Context) error {
	connConfig, err := pgx.ParseConfig(d.cfg.DSN)
	if err != nil {
		return fmt.Errorf("failed to parse postgres DSN: %w", err)
	}
	
	connStr := stdlib.RegisterConnConfig(connConfig)
	
	db, err := sql.Open("pgx", connStr)
	if err != nil {
		return fmt.Errorf("failed to connect to postgres: %w", err)
	}
	
	db.SetConnMaxLifetime(time.Minute * 3)
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(10)
	
	d.db = db
	
	if d.cfg.CreateHealthTable {
		if err := d.createHealthTable(ctx); err != nil {
			return err
		}
	}
	
	d.status = StatusUp
	return nil
}

func (d *postgresDriver) createHealthTable(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, d.cfg.ConnectTimeout)
	defer cancel()
	
	_, err := d.db.ExecContext(ctx, `
		CREATE TABLE IF NOT EXISTS _health_check (
			id SERIAL PRIMARY KEY,
			last_check TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			status TEXT
		)
	`)
	return err
}

func (d *postgresDriver) Ping(ctx context.Context) error {
	start := time.Now()
	
	ctx, cancel := context.WithTimeout(ctx, d.cfg.ConnectTimeout)
	defer cancel()
	
	err := d.db.PingContext(ctx)
	
	d.metrics["db_ping_latency_ms"] = float64(time.Since(start).Milliseconds())
	
	if err != nil {
		d.status = StatusDown
		return err
	}
	
	d.status = StatusUp
	return nil
}

func (d *postgresDriver) CheckReadWrite(ctx context.Context) error {
	if d.db == nil {
		return fmt.Errorf("database connection not established")
	}
	
	// Write test
	writeStart := time.Now()
	writeCtx, writeCancel := context.WithTimeout(ctx, d.cfg.WriteTimeout)
	defer writeCancel()
	
	_, err := d.db.ExecContext(writeCtx, `
		INSERT INTO _health_check (status) VALUES ($1)
		ON CONFLICT (id) DO UPDATE SET last_check = NOW(), status = $1
		WHERE _health_check.id = 1
	`, "healthy")
	
	d.metrics["db_write_latency_ms"] = float64(time.Since(writeStart).Milliseconds())
	
	if err != nil {
		d.status = StatusDegraded
		return fmt.Errorf("write test failed: %w", err)
	}
	
	// Read test
	readStart := time.Now()
	readCtx, readCancel := context.WithTimeout(ctx, d.cfg.ReadTimeout)
	defer readCancel()
	
	var status string
	err = d.db.QueryRowContext(readCtx, "SELECT status FROM _health_check WHERE id = 1").Scan(&status)
	
	d.metrics["db_read_latency_ms"] = float64(time.Since(readStart).Milliseconds())
	
	if err != nil {
		d.status = StatusDegraded
		return fmt.Errorf("read test failed: %w", err)
	}
	
	d.status = StatusUp
	return nil
}

func (d *postgresDriver) Close() error {
	if d.db != nil {
		return d.db.Close()
	}
	return nil
}

func (d *postgresDriver) Status() Status {
	return d.status
}

func (d *postgresDriver) Metrics() map[string]float64 {
	return d.metrics
}
```

## Integration with Health Checks

The database drivers will be integrated with the standard healthcheck binary:

```go
// cmd/healthcheck/main.go

// Example integration for PostgreSQL monitoring
func monitorPostgres(cfg Config) {
	driver, err := db.NewDriver(db.Config{
		DSN:              cfg.PostgresDSN,
		ConnectTimeout:   5 * time.Second,
		ReadTimeout:      2 * time.Second,
		WriteTimeout:     2 * time.Second,
		MaxRetries:       3,
		RetryInterval:    1 * time.Second,
		CreateHealthTable: true,
	})
	if err != nil {
		logger.Error("Failed to create postgres driver", "error", err)
		os.Exit(1)
	}
	
	// Connect to database
	ctx := context.Background()
	if err := driver.Connect(ctx); err != nil {
		logger.Error("Failed to connect to postgres", "error", err)
		os.Exit(1)
	}
	
	// Register metrics with Prometheus
	dbUp := prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "db_up",
		Help: "1 if the database is up, 0 if down",
	})
	prometheus.MustRegister(dbUp)
	
	dbReadLatency := prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "db_read_latency_ms",
		Help: "Database read latency in milliseconds",
	})
	prometheus.MustRegister(dbReadLatency)
	
	dbWriteLatency := prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "db_write_latency_ms", 
		Help: "Database write latency in milliseconds",
	})
	prometheus.MustRegister(dbWriteLatency)
	
	// Start monitoring loop
	go func() {
		for {
			// Ping database
			if err := driver.Ping(ctx); err != nil {
				logger.Error("Database ping failed", "error", err)
				dbUp.Set(0)
			} else {
				dbUp.Set(1)
			}
			
			// Check read/write operations
			if err := driver.CheckReadWrite(ctx); err != nil {
				logger.Error("Database read/write test failed", "error", err)
			}
			
			// Update metrics
			metrics := driver.Metrics()
			if readLatency, ok := metrics["db_read_latency_ms"]; ok {
				dbReadLatency.Set(readLatency)
			}
			if writeLatency, ok := metrics["db_write_latency_ms"]; ok {
				dbWriteLatency.Set(writeLatency)
			}
			
			time.Sleep(15 * time.Second)
		}
	}()
}
```

## Docker Integration

The database health checks will be integrated into our Docker services using our standard pattern:

```dockerfile
# Example Dockerfile for PostgreSQL service
FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM postgres:14

# Copy healthcheck binary from builder
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# Expose PostgreSQL, metrics, and health ports
EXPOSE 5432
EXPOSE 9091

# Use healthcheck wrapper to run PostgreSQL server
CMD ["healthcheck", "--export-prom", ":9091", "--", "docker-entrypoint.sh", "postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
```

## Prometheus Metrics

The database health probe will export the following metrics:

- `db_up{db_name="postgres", db_role="primary"}` - 1 if database is up, 0 if down
- `db_read_latency_ms{db_name="postgres", db_role="primary"}` - Read latency in milliseconds
- `db_write_latency_ms{db_name="postgres", db_role="primary"}` - Write latency in milliseconds
- `db_connection_count{db_name="postgres", db_role="primary"}` - Current number of connections
- `db_connection_errors_total{db_name="postgres", db_role="primary"}` - Total connection errors

Labels:
- `db_name`: Database type (postgres, mysql, sqlite, mssql)
- `db_role`: Role of the database (primary, replica, etc.)

## Testing Strategy

We will implement comprehensive testing for database health checks:

### Unit Tests

Using sqlmock to test database driver functions:

```go
// internal/db/postgres_test.go

func TestPostgresDriver_Ping(t *testing.T) {
	// Create a new mock database
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create mock: %v", err)
	}
	defer db.Close()
	
	// Create driver with mocked db
	driver := &postgresDriver{
		cfg: Config{
			ConnectTimeout: 1 * time.Second,
		},
		db:     db,
		status: StatusDown,
		metrics: make(map[string]float64),
	}
	
	// Setup expectation
	mock.ExpectPing()
	
	// Call Ping
	err = driver.Ping(context.Background())
	
	// Assert
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}
	
	if driver.status != StatusUp {
		t.Errorf("Expected status %s, got %s", StatusUp, driver.status)
	}
	
	// Verify expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}
```

### Integration Tests

Using docker-compose to test with real databases:

```yaml
# docker-compose.db.yml
version: '3.8'

services:
  postgres-test:
    image: postgres:14
    environment:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
      POSTGRES_DB: test
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "test"]
      interval: 5s
      timeout: 3s
      retries: 3

  mysql-test:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: test
      MYSQL_DATABASE: test
      MYSQL_USER: test
      MYSQL_PASSWORD: test
    ports:
      - "3307:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "test", "-ptest"]
      interval: 5s
      timeout: 3s
      retries: 3
```

```go
// tests/integration/db_health_test.go

func TestDatabaseHealth_Integration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}
	
	// PostgreSQL test
	t.Run("PostgreSQL", func(t *testing.T) {
		cfg := db.Config{
			DSN:              "postgres://test:test@localhost:5433/test",
			ConnectTimeout:   5 * time.Second,
			ReadTimeout:      2 * time.Second,
			WriteTimeout:     2 * time.Second,
			CreateHealthTable: true,
		}
		
		driver, err := db.NewDriver(cfg)
		if err != nil {
			t.Fatalf("Failed to create driver: %v", err)
		}
		
		ctx := context.Background()
		if err := driver.Connect(ctx); err != nil {
			t.Fatalf("Failed to connect: %v", err)
		}
		defer driver.Close()
		
		if err := driver.CheckReadWrite(ctx); err != nil {
			t.Errorf("Read/write test failed: %v", err)
		}
		
		if status := driver.Status(); status != db.StatusUp {
			t.Errorf("Expected status %s, got %s", db.StatusUp, status)
		}
	})
	
	// Similar tests for MySQL, SQLite, etc.
}
```

## Implementation Plan

1. Create base database driver interface and factory method
2. Implement PostgreSQL driver as highest priority
3. Add unit tests with sqlmock
4. Configure integration tests with docker-compose
5. Integrate with healthcheck binary
6. Update Dockerfile templates for database services
7. Implement MySQL driver
8. Implement SQLite driver (for local development)
9. Implement MSSQL driver (if needed)
10. Create example Grafana dashboard for database health metrics

## Example Alert Rules

```yaml
# prometheus/rules/database_alerts.yml
groups:
- name: database_alerts
  rules:
  - alert: DatabaseDown
    expr: db_up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Database {{ $labels.db_name }} ({{ $labels.db_role }}) is down"
      description: "Database has been down for more than 1 minute."
      
  - alert: DatabaseHighLatency
    expr: db_read_latency_ms > 100 or db_write_latency_ms > 200
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Database {{ $labels.db_name }} high latency"
      description: "Database is experiencing high latency: {{ $value }}ms"
```

## Conclusion

This design provides a standardized approach to database health monitoring across our platform. By implementing common interfaces and leveraging our existing healthcheck infrastructure, we ensure consistent reporting and metrics collection for all database services.

The implementation prioritizes PostgreSQL as our primary database technology, with support for other database types based on project requirements. The modular design allows for easy extension to additional database types in the future.