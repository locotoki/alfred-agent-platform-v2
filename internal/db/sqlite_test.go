package db

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

// TestSQLiteDriver_Connect tests the Connect method of the SQLite driver
func TestSQLiteDriver_Connect(t *testing.T) {
	// Create a new mock database
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create mock database: %v", err)
	}
	defer db.Close()

	// Create a new SQLite driver with mock DB
	driver := &sqliteDriver{
		cfg: Config{
			DSN:                 "file:test.db",
			ConnectTimeout:      1 * time.Second,
			ReadTimeout:         1 * time.Second,
			WriteTimeout:        1 * time.Second,
			TableCreationTimeout: 1 * time.Second,
			MaxOpenConns:        10,
			MaxIdleConns:        5,
			ConnMaxLifetime:     5 * time.Minute,
			ConnMaxIdleTime:     5 * time.Minute,
			CreateHealthTable:   true,
		},
		status:  StatusDown,
		metrics: make(map[string]float64),
	}

	// Test successful connection
	mock.ExpectPing()
	mock.ExpectExec("PRAGMA foreign_keys = ON").WillReturnResult(sqlmock.NewResult(0, 0))
	mock.ExpectExec("PRAGMA journal_mode = WAL").WillReturnResult(sqlmock.NewResult(0, 0))
	mock.ExpectExec("CREATE TABLE IF NOT EXISTS alfred_health_check").WillReturnResult(sqlmock.NewResult(0, 0))

	// Replace the sql.Open function to return our mock
	originalSQLOpen := sqlOpen
	sqlOpen = func(driverName, dataSourceName string) (*sql.DB, error) {
		return db, nil
	}
	defer func() { sqlOpen = originalSQLOpen }()

	// Call Connect
	err = driver.Connect(context.Background())
	if err != nil {
		t.Errorf("Connect() error = %v", err)
	}

	// Check that all expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}

	// Check status and metrics
	if driver.status != StatusUp {
		t.Errorf("Expected status to be %v, got %v", StatusUp, driver.status)
	}
	if driver.metrics["db_connection_success"] != 1 {
		t.Errorf("Expected db_connection_success to be 1, got %v", driver.metrics["db_connection_success"])
	}
	if driver.metrics["db_table_creation_success"] != 1 {
		t.Errorf("Expected db_table_creation_success to be 1, got %v", driver.metrics["db_table_creation_success"])
	}
	if driver.metrics["db_wal_enabled"] != 1 {
		t.Errorf("Expected db_wal_enabled to be 1, got %v", driver.metrics["db_wal_enabled"])
	}
}

// TestSQLiteDriver_Ping tests the Ping method of the SQLite driver
func TestSQLiteDriver_Ping(t *testing.T) {
	// Create a new mock database
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create mock database: %v", err)
	}
	defer db.Close()

	// Create a new SQLite driver with mock DB
	driver := &sqliteDriver{
		cfg: Config{
			DSN:          "file:test.db",
			PingTimeout:  1 * time.Second,
		},
		status:  StatusUp,
		metrics: make(map[string]float64),
		db:      db,
	}

	// Setup expectation
	mock.ExpectPing()

	// Call Ping
	err = driver.Ping(context.Background())
	if err != nil {
		t.Errorf("Ping() error = %v", err)
	}

	// Check that all expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}

	// Check metrics
	if driver.metrics["db_ping_success"] != 1 {
		t.Errorf("Expected db_ping_success to be 1, got %v", driver.metrics["db_ping_success"])
	}
	if driver.metrics["db_ping_latency_seconds"] <= 0 {
		t.Errorf("Expected db_ping_latency_seconds to be greater than 0, got %v", driver.metrics["db_ping_latency_seconds"])
	}
}

// TestSQLiteDriver_CheckReadWrite tests the CheckReadWrite method
func TestSQLiteDriver_CheckReadWrite(t *testing.T) {
	// Create a new mock database
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create mock database: %v", err)
	}
	defer db.Close()

	// Create a new SQLite driver with mock DB
	driver := &sqliteDriver{
		cfg: Config{
			DSN:           "file:test.db",
			ReadTimeout:   1 * time.Second,
			WriteTimeout:  1 * time.Second,
		},
		status:  StatusUp,
		metrics: make(map[string]float64),
		db:      db,
	}

	// Setup write expectation
	mock.ExpectExec("INSERT OR REPLACE INTO alfred_health_check").
		WithArgs(sqlmock.AnyArg(), "healthy").
		WillReturnResult(sqlmock.NewResult(1, 1))

	// Capture the timestamp for verification
	var capturedTimestamp int64

	// Hook into the write operation to capture the timestamp
	originalExecContext := execContext
	execContext = func(ctx context.Context, db *sql.DB, query string, args ...interface{}) (sql.Result, error) {
		if len(args) > 0 {
			if ts, ok := args[0].(int64); ok {
				capturedTimestamp = ts
			}
		}
		return mock.Conn().ExecContext(ctx, query, args...)
	}
	defer func() { execContext = originalExecContext }()

	// Setup read expectation with the captured timestamp
	rows := sqlmock.NewRows([]string{"check_time", "check_value"})
	
	// We'll set this after capturing the timestamp during write
	setRowsCallback := func() {
		rows.AddRow(capturedTimestamp, "healthy")
		mock.ExpectQuery("SELECT check_time, check_value FROM alfred_health_check WHERE id = 1").
			WillReturnRows(rows)
	}

	// Call CheckReadWrite
	err = driver.CheckReadWrite(context.Background())
	
	// Now add the rows after the write has happened and the timestamp is captured
	setRowsCallback()
	
	if err != nil {
		t.Errorf("CheckReadWrite() error = %v", err)
	}

	// Check that all expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}

	// Check metrics and status
	if driver.metrics["db_write_success"] != 1 {
		t.Errorf("Expected db_write_success to be 1, got %v", driver.metrics["db_write_success"])
	}
	if driver.metrics["db_read_success"] != 1 {
		t.Errorf("Expected db_read_success to be 1, got %v", driver.metrics["db_read_success"])
	}
	if driver.status != StatusUp {
		t.Errorf("Expected status to be %v, got %v", StatusUp, driver.status)
	}
}

// TestSQLiteDriver_Status tests the Status method
func TestSQLiteDriver_Status(t *testing.T) {
	// Create a new SQLite driver
	driver := &sqliteDriver{
		status:  StatusDegraded,
		metrics: make(map[string]float64),
	}

	// Check status
	if status := driver.Status(); status != StatusDegraded {
		t.Errorf("Status() = %v, want %v", status, StatusDegraded)
	}
}

// TestSQLiteDriver_Metrics tests the Metrics method
func TestSQLiteDriver_Metrics(t *testing.T) {
	// Create a new SQLite driver
	driver := &sqliteDriver{
		status: StatusUp,
		metrics: map[string]float64{
			"db_connection_success":       1,
			"db_ping_success":             1,
			"db_read_success":             1,
			"db_write_success":            1,
			"db_connection_latency_seconds": 0.1,
			"db_ping_latency_seconds":     0.05,
			"db_read_latency_seconds":     0.03,
			"db_write_latency_seconds":    0.02,
		},
	}

	// Get metrics
	metrics := driver.Metrics()

	// Check service health metric based on status
	if metrics["service_health"] != 1.0 {
		t.Errorf("Expected service_health to be 1.0, got %v", metrics["service_health"])
	}

	// Check driver type metric
	if metrics["db_driver_type"] != 3 {
		t.Errorf("Expected db_driver_type to be 3, got %v", metrics["db_driver_type"])
	}

	// Check that all original metrics are included
	for key, value := range driver.metrics {
		if metrics[key] != value {
			t.Errorf("Expected metrics[%s] to be %v, got %v", key, value, metrics[key])
		}
	}
}

// Mock sql.DB functions for testing
var (
	sqlOpen = sql.Open
	execContext = func(ctx context.Context, db *sql.DB, query string, args ...interface{}) (sql.Result, error) {
		return db.ExecContext(ctx, query, args...)
	}
)