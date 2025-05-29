package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/microsoft/go-mssqldb" // MSSQL driver
)

// mssqlDriver implements the Driver interface for MSSQL databases
type mssqlDriver struct {
	cfg     Config
	db      *sql.DB
	status  Status
	metrics map[string]float64
}

// newMSSQLDriver creates a new MSSQL driver
func newMSSQLDriver(cfg Config) Driver {
	return &mssqlDriver{
		cfg:     cfg,
		status:  StatusDown,
		metrics: make(map[string]float64),
	}
}

// Connect establishes a connection to the MSSQL database
func (d *mssqlDriver) Connect(ctx context.Context) error {
	startTime := time.Now()

	// Open database connection - using sqlserver driver name for MSSQL
	db, err := sql.Open("sqlserver", d.cfg.DSN)
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
	connectCtx, cancel := context.WithTimeout(ctx, d.cfg.ConnectTimeout)
	defer cancel()

	if err := db.PingContext(connectCtx); err != nil {
		d.status = StatusDown
		d.metrics["db_connection_success"] = 0
		d.metrics["db_connection_latency_seconds"] = time.Since(startTime).Seconds()
		return fmt.Errorf("failed to ping database: %w", err)
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
func (d *mssqlDriver) Ping(ctx context.Context) error {
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
func (d *mssqlDriver) CheckReadWrite(ctx context.Context) error {
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

	// MSSQL-specific upsert using MERGE statement
	_, err := d.db.ExecContext(writeCtx, `
		MERGE INTO alfred_health_check AS target
		USING (SELECT 1 AS id, @p1 AS check_time, @p2 AS check_value) AS source
		ON target.id = source.id
		WHEN MATCHED THEN
			UPDATE SET check_time = source.check_time, check_value = source.check_value
		WHEN NOT MATCHED THEN
			INSERT (id, check_time, check_value)
			VALUES (source.id, source.check_time, source.check_value);
	`, timestamp, "healthy")

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
		"SELECT TOP 1 check_time, check_value FROM alfred_health_check ORDER BY check_time DESC").
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
func (d *mssqlDriver) Close() error {
	if d.db != nil {
		return d.db.Close()
	}
	return nil
}

// Status returns the current database status
func (d *mssqlDriver) Status() Status {
	return d.status
}

// Metrics returns the database metrics
func (d *mssqlDriver) Metrics() map[string]float64 {
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
func (d *mssqlDriver) createHealthTable(ctx context.Context, db *sql.DB) error {
	createCtx, cancel := context.WithTimeout(ctx, d.cfg.TableCreationTimeout)
	defer cancel()

	// MSSQL-specific table creation syntax
	_, err := db.ExecContext(createCtx, `
		IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'alfred_health_check')
		BEGIN
			CREATE TABLE alfred_health_check (
				id INT PRIMARY KEY,
				check_time BIGINT NOT NULL,
				check_value NVARCHAR(255) NOT NULL
			)
		END
	`)

	if err != nil {
		return fmt.Errorf("failed to create health check table: %w", err)
	}

	return nil
}
