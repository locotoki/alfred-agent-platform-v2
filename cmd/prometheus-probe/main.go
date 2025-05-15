package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
	
	"github.com/locotoki/alfred-agent-platform-v2/internal/prometheus"
)

func main() {
	var (
		prometheusURL    string
		prometheusProbe  bool
		timeout          int
		verbose          bool
		help             bool
	)

	// Parse command-line flags
	flag.BoolVar(&prometheusProbe, "prometheus", false, "Enable Prometheus health check")
	flag.StringVar(&prometheusURL, "prometheus-url", "http://localhost:9090/api/v1/query?query=up", "Prometheus API endpoint to probe")
	flag.IntVar(&timeout, "timeout", 10, "Request timeout in seconds")
	flag.BoolVar(&verbose, "verbose", false, "Enable verbose output")
	flag.BoolVar(&help, "help", false, "Show help message")
	flag.Parse()

	if help {
		fmt.Println("Prometheus Health Probe")
		fmt.Println("Usage: prometheus-probe [options]")
		fmt.Println("\nOptions:")
		flag.PrintDefaults()
		os.Exit(0)
	}

	if !prometheusProbe {
		fmt.Println("Error: Prometheus probe not enabled. Use --prometheus flag to enable.")
		os.Exit(1)
	}

	// Configure HTTP client with timeout
	client := &http.Client{
		Timeout: time.Duration(timeout) * time.Second,
	}

	// Perform health check
	checker := prometheus.NewHealthChecker(client, prometheusURL, verbose)
	status, err := checker.Check()
	
	if err != nil {
		log.Printf("Health check failed: %v", err)
		os.Exit(2)
	}

	// Output status based on health check result
	switch status {
	case prometheus.StatusOK:
		fmt.Println("Prometheus health: OK")
		os.Exit(0)
	case prometheus.StatusDegraded:
		fmt.Println("Prometheus health: DEGRADED")
		os.Exit(1)
	case prometheus.StatusError:
		fmt.Println("Prometheus health: ERROR")
		os.Exit(2)
	default:
		fmt.Println("Prometheus health: UNKNOWN")
		os.Exit(3)
	}
}