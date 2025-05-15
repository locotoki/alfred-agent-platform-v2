package db

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestMySQLDriver_Ping(t *testing.T) {
	// Create a new mock database
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create mock: %v", err)
	}
	defer db.Close()
	
	// Create driver with mocked db
	driver := &mysqlDriver{
		cfg: Config{
			PingTimeout: 1 * time.Second,
		},
		db:      db,
		status:  StatusDown,
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
	
	// Verify metrics
	if _, ok := driver.metrics["db_ping_latency_seconds"]; !ok {
		t.Error("Expected db_ping_latency_seconds metric to be set")
	}
	
	if value, ok := driver.metrics["db_ping_success"]; !ok || value != 1 {
		t.Errorf("Expected db_ping_success metric to be 1, got %v", value)
	}
	
	// Verify expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestMySQLDriver_CheckReadWrite(t *testing.T) {
	// Create a new mock database
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create mock: %v", err)
	}
	defer db.Close()
	
	// Create driver with mocked db
	driver := &mysqlDriver{
		cfg: Config{
			ReadTimeout:  1 * time.Second,
			WriteTimeout: 1 * time.Second,
		},
		db:      db,
		status:  StatusDown,
		metrics: make(map[string]float64),
	}
	
	// Setup expectations for write
	mock.ExpectExec("INSERT INTO alfred_health_check").
		WithArgs(sqlmock.AnyArg(), "healthy", sqlmock.AnyArg(), "healthy").
		WillReturnResult(sqlmock.NewResult(1, 1))
	
	// Setup expectations for read
	rows := sqlmock.NewRows([]string{"check_time", "check_value"}).
		AddRow(time.Now().Unix(), "healthy")
	mock.ExpectQuery("SELECT check_time, check_value FROM alfred_health_check").
		WillReturnRows(rows)
	
	// Call CheckReadWrite
	err = driver.CheckReadWrite(context.Background())
	
	// Assert
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}
	
	if driver.status != StatusUp {
		t.Errorf("Expected status %s, got %s", StatusUp, driver.status)
	}
	
	// Verify metrics
	if _, ok := driver.metrics["db_read_latency_seconds"]; !ok {
		t.Error("Expected db_read_latency_seconds metric to be set")
	}
	
	if _, ok := driver.metrics["db_write_latency_seconds"]; !ok {
		t.Error("Expected db_write_latency_seconds metric to be set")
	}
	
	if value, ok := driver.metrics["db_read_success"]; !ok || value != 1 {
		t.Errorf("Expected db_read_success metric to be 1, got %v", value)
	}
	
	if value, ok := driver.metrics["db_write_success"]; !ok || value != 1 {
		t.Errorf("Expected db_write_success metric to be 1, got %v", value)
	}
	
	// Verify expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}

func TestMySQLDriver_Metrics(t *testing.T) {
	// Create driver
	driver := &mysqlDriver{
		status:  StatusUp,
		metrics: map[string]float64{
			"db_connection_success":        1,
			"db_ping_success":              1,
			"db_read_success":              1,
			"db_write_success":             1,
			"db_connection_latency_seconds": 0.05,
			"db_ping_latency_seconds":      0.01,
			"db_read_latency_seconds":      0.02,
			"db_write_latency_seconds":     0.03,
		},
	}
	
	// Get metrics
	metrics := driver.Metrics()
	
	// Assert service_health metric is set based on status
	if value, ok := metrics["service_health"]; !ok || value != 1.0 {
		t.Errorf("Expected service_health metric to be 1.0, got %v", value)
	}
	
	// Test with degraded status
	driver.status = StatusDegraded
	metrics = driver.Metrics()
	if value, ok := metrics["service_health"]; !ok || value != 0.5 {
		t.Errorf("Expected service_health metric to be 0.5, got %v", value)
	}
	
	// Test with down status
	driver.status = StatusDown
	metrics = driver.Metrics()
	if value, ok := metrics["service_health"]; !ok || value != 0.0 {
		t.Errorf("Expected service_health metric to be 0.0, got %v", value)
	}
}

func TestMySQLDriver_ErrorHandling(t *testing.T) {
	// Create a new mock database
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create mock: %v", err)
	}
	defer db.Close()
	
	// Create driver with mocked db
	driver := &mysqlDriver{
		cfg: Config{
			PingTimeout: 1 * time.Second,
		},
		db:      db,
		status:  StatusUp,
		metrics: make(map[string]float64),
	}
	
	// Setup expectation for ping error
	mock.ExpectPing().WillReturnError(fmt.Errorf("connection refused"))
	
	// Call Ping
	err = driver.Ping(context.Background())
	
	// Assert
	if err == nil {
		t.Error("Expected error, got nil")
	}
	
	if driver.status != StatusDown {
		t.Errorf("Expected status %s, got %s", StatusDown, driver.status)
	}
	
	// Verify metrics
	if value, ok := driver.metrics["db_ping_success"]; !ok || value != 0 {
		t.Errorf("Expected db_ping_success metric to be 0, got %v", value)
	}
	
	// Verify expectations were met
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Errorf("Unfulfilled expectations: %v", err)
	}
}