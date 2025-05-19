// Package db provides standardized database health check drivers
package db

import (
	"context"
	"fmt"
	"strings"
	"time"
)

// Status represents the health status of a database
type Status string

const (
	// StatusUp indicates the database is fully operational
	StatusUp Status = "up"

	// StatusDown indicates the database is not available
	StatusDown Status = "down"

	// StatusDegraded indicates the database is available but experiencing issues
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

// Placeholder functions to be implemented in specific drivers
func newPostgresDriver(cfg Config) Driver {
	// Implementation in postgres.go
	return nil
}

func newMySQLDriver(cfg Config) Driver {
	// Implementation in mysql.go
	return nil
}

func newSQLiteDriver(cfg Config) Driver {
	// Implementation in sqlite.go
	return nil
}

func newMSSQLDriver(cfg Config) Driver {
	// Implementation in mssql.go
	return nil
}
