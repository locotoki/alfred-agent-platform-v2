package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/locotoki/alfred-agent-platform-v2/internal/db"
	"github.com/locotoki/alfred-agent-platform-v2/internal/trace"
)

var (
	// Command-line flags
	dbType        = flag.String("db-type", "", "Database type: postgres, mysql, sqlite, mssql")
	dbDSN         = flag.String("db-dsn", "", "Database connection string (DSN)")
	runOnce       = flag.Bool("once", false, "Run health check once and exit")
	interval      = flag.Duration("interval", 60*time.Second, "Interval between health checks")
	timeout       = flag.Duration("timeout", 10*time.Second, "Timeout for health check operations")
	createTable   = flag.Bool("create-table", true, "Create health check table if it doesn't exist")
	showVersion   = flag.Bool("version", false, "Show version and exit")
	showHelp      = flag.Bool("help", false, "Show help")
	serviceName   = flag.String("service-name", "healthcheck", "Service name for tracing")
	traceEndpoint = flag.String("trace-endpoint", "", "OTLP/HTTP endpoint for tracing (disabled if empty)")
	probe         = flag.String("probe", "", "Probe type (for command line and tracing clarity)")
)

// Version information (set during build)
var (
	Version   = "dev"
	BuildTime = "unknown"
	GitCommit = "unknown"
)

func main() {
	// Parse command-line flags
	flag.Parse()

	// Check for environment variables overrides
	if os.Getenv("TRACE_ENDPOINT") != "" {
		*traceEndpoint = os.Getenv("TRACE_ENDPOINT")
	}

	// Show version information if requested
	if *showVersion {
		fmt.Printf("Alfred Healthcheck %s\n", Version)
		fmt.Printf("Build time: %s\n", BuildTime)
		fmt.Printf("Git commit: %s\n", GitCommit)
		os.Exit(0)
	}

	// Show help if requested
	if *showHelp {
		fmt.Printf("Alfred Healthcheck - Database health monitoring tool\n\n")
		fmt.Printf("Usage: healthcheck [options]\n\n")
		fmt.Printf("Options:\n")
		flag.PrintDefaults()
		os.Exit(0)
	}

	// Initialize OpenTelemetry if endpoint provided
	if *traceEndpoint != "" {
		shutdown, err := trace.Init(*traceEndpoint, *serviceName)
		if err != nil {
			log.Fatalf("Error initializing OpenTelemetry: %v", err)
		}
		defer func() {
			if err := shutdown(context.Background()); err != nil {
				log.Printf("Error shutting down tracer provider: %v", err)
			}
		}()
		log.Printf("OpenTelemetry tracing enabled, exporting to %s", *traceEndpoint)
	}

	// Support noop probe for tracing-only tests
	if *probe == "noop" {
		ctx := context.Background()
		if *traceEndpoint != "" {
			ctx, end := trace.StartSpan(ctx, "probe.noop")
			defer end()
			trace.AddAttribute(ctx, "result", "up")
			trace.AddAttribute(ctx, "service.name", *serviceName)
		}
		log.Println("Noop probe executed successfully")
		os.Exit(0)
	}

	// Validate required flags
	if *dbType == "" {
		log.Fatal("Error: --db-type flag is required")
	}

	if *dbDSN == "" {
		log.Fatal("Error: --db-dsn flag is required")
	}

	// Create database config
	cfg := db.Config{
		DSN:                 *dbDSN,
		ConnectTimeout:      *timeout,
		PingTimeout:         *timeout,
		ReadTimeout:         *timeout,
		WriteTimeout:        *timeout,
		TableCreationTimeout: *timeout,
		MaxRetries:          3,
		RetryInterval:       time.Second,
		CreateHealthTable:   *createTable,
		MaxOpenConns:        5,
		MaxIdleConns:        2,
		ConnMaxLifetime:     time.Minute * 5,
		ConnMaxIdleTime:     time.Minute * 2,
	}

	// Create DSN based on database type
	switch *dbType {
	case "postgres":
		cfg.DSN = fmt.Sprintf("postgres://%s", *dbDSN)
	case "mysql":
		cfg.DSN = fmt.Sprintf("mysql://%s", *dbDSN)
	case "sqlite":
		cfg.DSN = fmt.Sprintf("file:%s", *dbDSN)
	case "mssql":
		cfg.DSN = fmt.Sprintf("sqlserver://%s", *dbDSN)
	default:
		log.Fatalf("Error: unsupported database type: %s", *dbType)
	}

	// Create database driver
	driver, err := db.NewDriver(cfg)
	if err != nil {
		log.Fatalf("Error creating database driver: %v", err)
	}
	defer driver.Close()

	// Setup signal handling for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	signalCh := make(chan os.Signal, 1)
	signal.Notify(signalCh, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-signalCh
		log.Printf("Received signal: %v, shutting down...", sig)
		cancel()
	}()

	// Run health check
	if *runOnce {
		// Single health check run
		if err := runHealthCheck(ctx, driver); err != nil {
			log.Printf("Health check failed: %v", err)
			os.Exit(1)
		}
		log.Printf("Health check successful, status: %s", driver.Status())
		os.Exit(0)
	} else {
		// Periodic health check
		ticker := time.NewTicker(*interval)
		defer ticker.Stop()

		// Run initial health check
		if err := runHealthCheck(ctx, driver); err != nil {
			log.Printf("Initial health check failed: %v", err)
		} else {
			log.Printf("Initial health check successful, status: %s", driver.Status())
		}

		// Run periodic health checks
		for {
			select {
			case <-ctx.Done():
				log.Println("Shutting down health check...")
				return
			case <-ticker.C:
				if err := runHealthCheck(ctx, driver); err != nil {
					log.Printf("Health check failed: %v", err)
				} else {
					log.Printf("Health check successful, status: %s", driver.Status())
				}
			}
		}
	}
}

// runHealthCheck runs a complete health check on the database
func runHealthCheck(ctx context.Context, driver db.Driver) error {
	// Start span if tracing is enabled
	if *traceEndpoint != "" {
		var end func()
		probeName := *probe
		if probeName == "" {
			probeName = *dbType
		}
		ctx, end = trace.StartSpan(ctx, "probe."+probeName)
		defer end()
		trace.AddAttribute(ctx, "service.name", *serviceName)
	}

	// Connect to database
	if err := driver.Connect(ctx); err != nil {
		if *traceEndpoint != "" {
			trace.AddAttribute(ctx, "result", "down")
			trace.AddAttribute(ctx, "error", err.Error())
		}
		return fmt.Errorf("connection failed: %w", err)
	}

	// Ping database
	if err := driver.Ping(ctx); err != nil {
		if *traceEndpoint != "" {
			trace.AddAttribute(ctx, "result", "down")
			trace.AddAttribute(ctx, "error", err.Error())
		}
		return fmt.Errorf("ping failed: %w", err)
	}

	// Read/write test
	if err := driver.CheckReadWrite(ctx); err != nil {
		if *traceEndpoint != "" {
			trace.AddAttribute(ctx, "result", "degraded")
			trace.AddAttribute(ctx, "error", err.Error())
		}
		return fmt.Errorf("read/write test failed: %w", err)
	}

	// Print metrics
	metrics := driver.Metrics()
	for k, v := range metrics {
		log.Printf("Metric %s: %.2f", k, v)
	}

	// Add result to span if tracing is enabled
	if *traceEndpoint != "" {
		trace.AddAttribute(ctx, "result", "up")
	}

	return nil
}