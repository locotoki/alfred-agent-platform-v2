package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq" // PostgreSQL driver
)

// postgresDriver implements the Driver interface for PostgreSQL databases
type postgresDriver struct {
	cfg     Config
	db      *sql.DB
	status  Status
	metrics map[string]float64
}

// NewPostgresDriver creates a new PostgreSQL driver
func NewPostgresDriver(cfg Config) Driver {
	return &postgresDriver{
		cfg:     cfg,
		status:  StatusDown,
		metrics: make(map[string]float64),
	}
}

// Connect establishes a connection to the PostgreSQL database
func (d *postgresDriver) Connect(ctx context.Context) error {
	startTime := time.Now()

	// Open database connection
	db, err := sql.Open("postgres", d.cfg.DSN)
	if err != nil {
		d.status = StatusDown
		d.metrics["db_connection_success"] = 0
		d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
		return fmt.Errorf("failed to open database connection: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(d.cfg.MaxOpenConns)
	db.SetMaxIdleConns(d.cfg.MaxIdleConns)
	db.SetConnMaxLifetime(d.cfg.ConnMaxLifetime)
	db.SetConnMaxIdleTime(d.cfg.ConnMaxIdleTime)

	// Test connection with context
	if err := db.PingContext(ctx); err != nil {
		d.status = StatusDown
		d.metrics["db_connection_success"] = 0
		d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
		return fmt.Errorf("failed to ping database: %w", err)
	}

	// Create health check table if enabled
	if d.cfg.CreateTable {
		if err := d.createHealthTable(ctx, db); err != nil {
			d.status = StatusDegraded
			d.metrics["db_connection_success"] = 0.5
			d.metrics["db_table_creation_success"] = 0
			d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
			return fmt.Errorf("failed to create health check table: %w", err)
		}
		d.metrics["db_table_creation_success"] = 1
	}

	d.db = db
	d.status = StatusUp
	d.metrics["db_connection_success"] = 1
	d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()

	return nil
}

// Ping checks if the database connection is still alive
func (d *postgresDriver) Ping(ctx context.Context) error {
	if d.db == nil {
		d.status = StatusDown
		d.metrics["db_ping_success"] = 0
		return fmt.Errorf("database connection not established")
	}

	startTime := time.Now()

	// Ping with timeout
	pingCtx, cancel := context.WithTimeout(ctx, d.cfg.PingTimeout)
	defer cancel()

	err := d.db.PingContext(pingCtx)
	d.metrics["db_ping_latency_seconds"] = time.Since(startTime).Seconds()

	if err != nil {
		d.status = StatusDown
		d.metrics["db_ping_success"] = 0
		return fmt.Errorf("failed to ping database: %w", err)
	}

	d.metrics["db_ping_success"] = 1
	return nil
}

// CheckReadWrite performs a read/write test on the health check table
func (d *postgresDriver) CheckReadWrite(ctx context.Context) error {
	if d.db == nil {
		d.status = StatusDown
		d.metrics["db_read_success"] = 0
		d.metrics["db_write_success"] = 0
		return fmt.Errorf("database connection not established")
	}

	// Test write operation
	writeStartTime := time.Now()
	writeCtx, writeCancel := context.WithTimeout(ctx, d.cfg.WriteTimeout)
	defer writeCancel()

	timestamp := time.Now().Unix()
	_, err := d.db.ExecContext(writeCtx,
		"INSERT INTO alfred_health_check (check_time, check_value) VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET check_time = $1, check_value = $2",
		timestamp, "healthy")

	d.metrics["db_write_latency_seconds"] = time.Since(writeStartTime).Seconds()

	if err != nil {
		d.status = StatusDegraded
		d.metrics["db_write_success"] = 0
		return fmt.Errorf("failed to write to health check table: %w", err)
	}

	d.metrics["db_write_success"] = 1

	// Test read operation
	readStartTime := time.Now()
	readCtx, readCancel := context.WithTimeout(ctx, d.cfg.ReadTimeout)
	defer readCancel()

	var storedTimestamp int64
	var storedValue string

	err = d.db.QueryRowContext(readCtx,
		"SELECT check_time, check_value FROM alfred_health_check ORDER BY check_time DESC LIMIT 1").
		Scan(&storedTimestamp, &storedValue)

	d.metrics["db_read_latency_seconds"] = time.Since(readStartTime).Seconds()

	if err != nil {
		d.status = StatusDegraded
		d.metrics["db_read_success"] = 0
		return fmt.Errorf("failed to read from health check table: %w", err)
	}

	// Verify read/write consistency
	if storedTimestamp != timestamp || storedValue != "healthy" {
		d.status = StatusDegraded
		d.metrics["db_read_success"] = 0.5
		return fmt.Errorf("inconsistent read/write: expected (%d, %s), got (%d, %s)",
			timestamp, "healthy", storedTimestamp, storedValue)
	}

	d.metrics["db_read_success"] = 1
	d.status = StatusUp

	return nil
}

// Close closes the database connection
func (d *postgresDriver) Close() error {
	if d.db != nil {
		return d.db.Close()
	}
	return nil
}

// Status returns the current database status
func (d *postgresDriver) Status() Status {
	return d.status
}

// Metrics returns the database metrics
func (d *postgresDriver) Metrics() map[string]float64 {
	metrics := make(map[string]float64)

	// Copy current metrics
	for k, v := range d.metrics {
		metrics[k] = v
	}

	// Add status metric
	switch d.status {
	case StatusUp:
		metrics["service_health"] = 1.0
	case StatusDegraded:
		metrics["service_health"] = 0.5
	case StatusDown:
		metrics["service_health"] = 0.0
	}

	return metrics
}

// createHealthTable creates the health check table if it doesn't exist
func (d *postgresDriver) createHealthTable(ctx context.Context, db *sql.DB) error {
	createCtx, cancel := context.WithTimeout(ctx, d.cfg.TableCreationTimeout)
	defer cancel()

	_, err := db.ExecContext(createCtx, `
		CREATE TABLE IF NOT EXISTS alfred_health_check (
			id SERIAL PRIMARY KEY,
			check_time BIGINT NOT NULL,
			check_value TEXT NOT NULL
		)
	`)

	if err != nil {
		return fmt.Errorf("failed to create health check table: %w", err)
	}

	return nil
}
