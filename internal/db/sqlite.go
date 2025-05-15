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

	// The modernc.org/sqlite driver uses the standard SQLite URI format
	// which already includes "file:" prefix, so we don't need to modify it
	dsn := d.cfg.DSN

	// Open database connection
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		d.status = StatusDown
		d.metrics["db_connection_success"] = 0
		d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
		return fmt.Errorf("failed to open database connection: %w", err)
	}

	// Configure connection pool
	// SQLite only supports 1 writer at a time, but can have multiple readers
	// Set a reasonable max open connections to prevent "database is locked" errors
	maxConn := d.cfg.MaxOpenConns
	if maxConn > 10 {
		maxConn = 10 // SQLite handles concurrency differently, so limit connections
	}
	db.SetMaxOpenConns(maxConn)
	db.SetMaxIdleConns(d.cfg.MaxIdleConns)
	db.SetConnMaxLifetime(d.cfg.ConnMaxLifetime)
	db.SetConnMaxIdleTime(d.cfg.ConnMaxIdleTime)

	// Test connection with context
	connectCtx, cancel := context.WithTimeout(ctx, d.cfg.ConnectTimeout)
	defer cancel()

	if err := db.PingContext(connectCtx); err != nil {
		d.status = StatusDown
		d.metrics["db_connection_success"] = 0
		d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
		return fmt.Errorf("failed to ping database: %w", err)
	}

	// Enable foreign keys using pragma (using the modernc.org driver method)
	if _, err := db.ExecContext(connectCtx, "PRAGMA foreign_keys = ON"); err != nil {
		d.status = StatusDegraded
		d.metrics["db_connection_success"] = 0.5
		d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
		return fmt.Errorf("failed to enable foreign keys: %w", err)
	}

	// Enable WAL mode for better concurrency
	if _, err := db.ExecContext(connectCtx, "PRAGMA journal_mode = WAL"); err != nil {
		// Not critical, so just log and continue
		d.metrics["db_wal_enabled"] = 0
	} else {
		d.metrics["db_wal_enabled"] = 1
	}

	// Create health check table if enabled
	if d.cfg.CreateHealthTable {
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
func (d *sqliteDriver) Ping(ctx context.Context) error {
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
func (d *sqliteDriver) CheckReadWrite(ctx context.Context) error {
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
	// Using SQLite's INSERT OR REPLACE syntax for upsert
	_, err := d.db.ExecContext(writeCtx,
		"INSERT OR REPLACE INTO alfred_health_check (id, check_time, check_value) VALUES (1, ?, ?)",
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
		"SELECT check_time, check_value FROM alfred_health_check WHERE id = 1").
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
func (d *sqliteDriver) Close() error {
	if d.db != nil {
		return d.db.Close()
	}
	return nil
}

// Status returns the current database status
func (d *sqliteDriver) Status() Status {
	return d.status
}

// Metrics returns the database metrics
func (d *sqliteDriver) Metrics() map[string]float64 {
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

	// Add driver type metric
	metrics["db_driver_type"] = 3 // 1=Postgres, 2=MySQL, 3=SQLite, 4=MSSQL

	return metrics
}

// createHealthTable creates the health check table if it doesn't exist
func (d *sqliteDriver) createHealthTable(ctx context.Context, db *sql.DB) error {
	createCtx, cancel := context.WithTimeout(ctx, d.cfg.TableCreationTimeout)
	defer cancel()

	// SQLite-specific table creation syntax
	_, err := db.ExecContext(createCtx, `
		CREATE TABLE IF NOT EXISTS alfred_health_check (
			id INTEGER PRIMARY KEY,
			check_time INTEGER NOT NULL,
			check_value TEXT NOT NULL
		)
	`)

	if err != nil {
		return fmt.Errorf("failed to create health check table: %w", err)
	}

	return nil
}