package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/locotoki/alfred-agent-platform-v2/internal/grafana"
)

func main() {
	var (
		grafanaURL  string
		grafanaAuth string
		timeout     int
		verbose     bool
		help        bool
	)

	// Parse command-line flags
	flag.StringVar(&grafanaURL, "grafana", "", "Grafana URL to check (e.g., http://grafana:3000)")
	flag.StringVar(&grafanaAuth, "grafana-auth", "", "Grafana authentication in format user:pass (basic auth) or user:token (API token)")
	flag.IntVar(&timeout, "timeout", 10, "Request timeout in seconds")
	flag.BoolVar(&verbose, "verbose", false, "Enable verbose output")
	flag.BoolVar(&help, "help", false, "Show help message")
	flag.Parse()

	// Show help if requested or if no URL provided
	if help || grafanaURL == "" {
		fmt.Printf("Grafana health probe\n\n")
		fmt.Printf("Usage: %s --grafana http://grafana:3000 [--grafana-auth user:pass] [--timeout 10] [--verbose]\n\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(0)
	}

	// Initialize health checker
	checker := &grafana.HealthChecker{
		GrafanaURL: grafanaURL,
		Auth:       grafanaAuth,
		Timeout:    time.Duration(timeout) * time.Second,
	}

	// Run health check
	status, err := checker.Check()

	// Handle errors and status
	if err != nil {
		if verbose {
			fmt.Fprintf(os.Stderr, "Error checking Grafana health: %v\n", err)
		}
		os.Exit(2)
	}

	if verbose {
		fmt.Printf("Grafana health status: %s\n", status)
	}

	// Set exit code based on status
	switch status {
	case grafana.StatusOK:
		os.Exit(0)
	case grafana.StatusDegraded:
		os.Exit(1)
	case grafana.StatusError:
		os.Exit(2)
	default:
		os.Exit(3)
	}
}