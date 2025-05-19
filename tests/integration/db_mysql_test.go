// +build integration

package integration

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/locotoki/alfred-agent-platform-v2/internal/db"
)

func TestMySQLDriver_Integration(t *testing.T) {
	// Skip in short mode
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	// Get MySQL DSN from environment or use default test DSN
	dsn := os.Getenv("MYSQL_TEST_DSN")
	if dsn == "" {
		dsn = "mysql://root:mysql@tcp(localhost:3306)/test"
	}

	// Create driver with configuration
	cfg := db.Config{
		DSN:                  dsn,
		ConnectTimeout:       5 * time.Second,
		PingTimeout:          2 * time.Second,
		ReadTimeout:          2 * time.Second,
		WriteTimeout:         2 * time.Second,
		TableCreationTimeout: 5 * time.Second,
		MaxOpenConns:         10,
		MaxIdleConns:         5,
		ConnMaxLifetime:      15 * time.Minute,
		ConnMaxIdleTime:      5 * time.Minute,
		CreateHealthTable:    true,
	}

	driver, err := db.NewDriver(cfg)
	if err != nil {
		t.Fatalf("Failed to create MySQL driver: %v", err)
	}

	// Connect to database
	ctx := context.Background()
	if err := driver.Connect(ctx); err != nil {
		t.Fatalf("Failed to connect to MySQL database: %v", err)
	}
	defer driver.Close()

	// Test ping
	if err := driver.Ping(ctx); err != nil {
		t.Errorf("Failed to ping MySQL database: %v", err)
	}

	// Test read/write
	if err := driver.CheckReadWrite(ctx); err != nil {
		t.Errorf("Failed to perform read/write test on MySQL database: %v", err)
	}

	// Check status
	if status := driver.Status(); status != db.StatusUp {
		t.Errorf("Expected MySQL database status to be %s, got %s", db.StatusUp, status)
	}

	// Check metrics
	metrics := driver.Metrics()
	t.Logf("MySQL metrics: %v", metrics)

	// Check service_health metric
	if value, ok := metrics["service_health"]; !ok || value != 1.0 {
		t.Errorf("Expected service_health metric to be 1.0, got %v", value)
	}
}
