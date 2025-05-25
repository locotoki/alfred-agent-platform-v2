package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"sync"
	"time"

	"github.com/spf13/cobra"
)

var (
	rps     int
	burst   int
	duration time.Duration
	endpoint string
	randomize bool
)

var workloadCmd = &cobra.Command{
	Use:   "workload",
	Short: "Generate synthetic workload for testing",
	Long:  `Generate synthetic workload against the platform endpoints with configurable RPS and burst patterns.`,
	RunE:  runWorkload,
}

func init() {
	workloadCmd.Flags().IntVar(&rps, "rps", 10, "Requests per second")
	workloadCmd.Flags().IntVar(&burst, "burst", 0, "Burst size (0 for steady rate)")
	workloadCmd.Flags().DurationVar(&duration, "duration", 5*time.Minute, "Test duration")
	workloadCmd.Flags().StringVar(&endpoint, "endpoint", "http://localhost:8080", "Target endpoint")
	workloadCmd.Flags().BoolVar(&randomize, "random", true, "Use random query mix")

	rootCmd.AddCommand(workloadCmd)
}

// Query templates for random mix
var queryTemplates = []string{
	"/api/v1/agents/list",
	"/api/v1/agents/status",
	"/api/v1/rag/query?q=what+is+alfred",
	"/api/v1/rag/query?q=how+to+deploy",
	"/api/v1/rag/query?q=architecture+overview",
	"/api/v1/metrics",
	"/api/v1/health",
	"/api/v1/healthz",
}

func runWorkload(cmd *cobra.Command, args []string) error {
	ctx, cancel := context.WithTimeout(context.Background(), duration)
	defer cancel()

	log.Printf("Starting synthetic workload: RPS=%d, Burst=%d, Duration=%s", rps, burst, duration)

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	var wg sync.WaitGroup
	ticker := time.NewTicker(time.Second / time.Duration(rps))
	defer ticker.Stop()

	totalRequests := 0
	successCount := 0
	errorCount := 0

	startTime := time.Now()

	for {
		select {
		case <-ctx.Done():
			wg.Wait()
			elapsed := time.Since(startTime)
			log.Printf("Workload completed: Total=%d, Success=%d, Errors=%d, Duration=%s",
				totalRequests, successCount, errorCount, elapsed)
			return nil
		case <-ticker.C:
			// Send burst or single request
			requestCount := 1
			if burst > 0 && totalRequests % (rps * 10) == 0 { // Burst every 10 seconds
				requestCount = burst
				log.Printf("Sending burst of %d requests", burst)
			}

			for i := 0; i < requestCount; i++ {
				wg.Add(1)
				go func() {
					defer wg.Done()

					// Select endpoint
					targetURL := endpoint
					if randomize && len(queryTemplates) > 0 {
						query := queryTemplates[rand.Intn(len(queryTemplates))]
						targetURL = endpoint + query
					}

					// Make request
					resp, err := client.Get(targetURL)
					if err != nil {
						log.Printf("Request error: %v", err)
						errorCount++
					} else {
						resp.Body.Close()
						if resp.StatusCode >= 200 && resp.StatusCode < 300 {
							successCount++
						} else {
							log.Printf("Request failed with status: %d", resp.StatusCode)
							errorCount++
						}
					}
					totalRequests++

					// Log progress every 100 requests
					if totalRequests % 100 == 0 {
						log.Printf("Progress: %d requests sent (%.1f%% success rate)",
							totalRequests, float64(successCount)/float64(totalRequests)*100)
					}
				}()
			}
		}
	}
}
