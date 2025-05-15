package db

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestNewMSSQLDriver(t *testing.T) {
	cfg := Config{
		DSN:                 "sqlserver://sa:Password123!@localhost:1433/tempdb",
		ConnectTimeout:      5 * time.Second,
		PingTimeout:         2 * time.Second,
		ReadTimeout:         2 * time.Second,
		WriteTimeout:        2 * time.Second,
		TableCreationTimeout: 5 * time.Second,
		MaxRetries:          3,
		RetryInterval:       time.Second,
		CreateHealthTable:   true,
		MaxOpenConns:        5,
		MaxIdleConns:        2,
		ConnMaxLifetime:     time.Minute * 5,
		ConnMaxIdleTime:     time.Minute * 2,
	}

	driver := newMSSQLDriver(cfg)
	
	// Verify driver was created with correct initial status
	assert.NotNil(t, driver)
	assert.Equal(t, StatusDown, driver.Status())
	
	// Verify metrics are initialized
	metrics := driver.Metrics()
	assert.NotNil(t, metrics)
	assert.Equal(t, 0.0, metrics["service_health"])
}

// Note: Add integration tests if a real MSSQL instance is available in the test environment
// For now, we're only testing the driver instantiation since connecting to a real
// database would require a live MSSQL instance.