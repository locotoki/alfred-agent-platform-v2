package integration

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/locotoki/alfred-agent-platform-v2/internal/db"
)

// TestSQLiteDriverIntegration performs an integration test with a real SQLite database
func TestSQLiteDriverIntegration(t *testing.T) {
	// Create a temporary database file
	dbFile := "/tmp/alfred_test_sqlite.db"
	
	// Cleanup after the test
	defer os.Remove(dbFile)

	// Create a new driver with the SQLite DSN
	// Note: for modernc.org/sqlite, the DSN format is the same as standard SQLite
	config := db.Config{
		DSN:                 "file:" + dbFile + "?_pragma=journal_mode(WAL)&_pragma=foreign_keys(ON)",
		ConnectTimeout:      5 * time.Second,
		PingTimeout:         2 * time.Second,
		ReadTimeout:         2 * time.Second,
		WriteTimeout:        2 * time.Second,
		TableCreationTimeout: 5 * time.Second,
		MaxRetries:          3,
		RetryInterval:       500 * time.Millisecond,
		CreateHealthTable:   true,
		MaxOpenConns:        10,
		MaxIdleConns:        5,
		ConnMaxLifetime:     5 * time.Minute,
		ConnMaxIdleTime:     5 * time.Minute,
	}

	driver, err := db.NewDriver(config)
	if err != nil {
		t.Fatalf("Failed to create SQLite driver: %v", err)
	}

	// Test Connect
	ctx := context.Background()
	if err := driver.Connect(ctx); err != nil {
		t.Fatalf("Failed to connect to SQLite database: %v", err)
	}
	defer driver.Close()

	// Check initial status
	if status := driver.Status(); status != db.StatusUp {
		t.Errorf("Expected status to be %v, got %v", db.StatusUp, status)
	}

	// Test Ping
	if err := driver.Ping(ctx); err != nil {
		t.Errorf("Failed to ping SQLite database: %v", err)
	}

	// Test CheckReadWrite
	if err := driver.CheckReadWrite(ctx); err != nil {
		t.Errorf("Failed read/write test: %v", err)
	}

	// Check metrics
	metrics := driver.Metrics()
	requiredMetrics := []string{
		"db_connection_success",
		"db_connection_latency_seconds",
		"db_ping_success",
		"db_ping_latency_seconds",
		"db_read_success",
		"db_read_latency_seconds",
		"db_write_success",
		"db_write_latency_seconds",
		"service_health",
		"db_driver_type",
	}

	for _, metricName := range requiredMetrics {
		if _, exists := metrics[metricName]; !exists {
			t.Errorf("Required metric %s is missing", metricName)
		}
	}

	// Check service_health is 1.0 (UP)
	if metrics["service_health"] != 1.0 {
		t.Errorf("Expected service_health to be 1.0, got %v", metrics["service_health"])
	}
	
	// Check driver type is 3 (SQLite)
	if metrics["db_driver_type"] != 3 {
		t.Errorf("Expected db_driver_type to be 3, got %v", metrics["db_driver_type"])
	}
}