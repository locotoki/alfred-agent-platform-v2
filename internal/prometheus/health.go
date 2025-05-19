package prometheus

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
)

// HealthStatus represents the health status of a Prometheus instance
type HealthStatus string

const (
	// StatusOK indicates Prometheus is healthy and all targets are up
	StatusOK HealthStatus = "ok"

	// StatusDegraded indicates Prometheus is running but some targets are down
	StatusDegraded HealthStatus = "degraded"

	// StatusError indicates Prometheus is not responding or has critical issues
	StatusError HealthStatus = "error"
)

// HealthChecker checks the health of a Prometheus instance
type HealthChecker struct {
	client      *http.Client
	url         string
	verbose     bool
}

// PrometheusResponse represents the response structure from Prometheus API
type PrometheusResponse struct {
	Status string `json:"status"`
	Data   struct {
		ResultType string `json:"resultType"`
		Result     []struct {
			Metric map[string]string `json:"metric"`
			Value  []interface{}     `json:"value"`
		} `json:"result"`
	} `json:"data"`
	ErrorType string `json:"errorType,omitempty"`
	Error     string `json:"error,omitempty"`
}

// NewHealthChecker creates a new Prometheus health checker
func NewHealthChecker(client *http.Client, url string, verbose bool) *HealthChecker {
	return &HealthChecker{
		client:  client,
		url:     url,
		verbose: verbose,
	}
}

// Check performs a health check against the Prometheus instance
func (c *HealthChecker) Check() (HealthStatus, error) {
	if c.verbose {
		log.Printf("Checking Prometheus health at %s", c.url)
	}

	req, err := http.NewRequest("GET", c.url, nil)
	if err != nil {
		return StatusError, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return StatusError, fmt.Errorf("failed to connect to Prometheus: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return StatusError, fmt.Errorf("Prometheus returned non-OK status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return StatusError, fmt.Errorf("failed to read response body: %w", err)
	}

	var promResp PrometheusResponse
	if err := json.Unmarshal(body, &promResp); err != nil {
		return StatusError, fmt.Errorf("failed to parse Prometheus response: %w", err)
	}

	// Check if Prometheus returned an error
	if promResp.Status != "success" {
		return StatusError, fmt.Errorf("Prometheus query failed: %s: %s",
			promResp.ErrorType, promResp.Error)
	}

	// No results means no targets are being monitored
	if len(promResp.Data.Result) == 0 {
		if c.verbose {
			log.Println("No targets found in Prometheus")
		}
		return StatusDegraded, nil
	}

	// Check if any targets are down (value[1] == 0)
	var upCount, downCount int
	for _, result := range promResp.Data.Result {
		// The value is [timestamp, "1"|"0"] where index 1 is a string
		if len(result.Value) >= 2 {
			valueStr, ok := result.Value[1].(string)
			if !ok {
				if c.verbose {
					log.Printf("Unexpected value format: %v", result.Value)
				}
				continue
			}

			if valueStr == "1" {
				upCount++
			} else {
				downCount++
				if c.verbose {
					instance := result.Metric["instance"]
					job := result.Metric["job"]
					log.Printf("Target down: instance=%s, job=%s", instance, job)
				}
			}
		}
	}

	if c.verbose {
		log.Printf("Targets: %d up, %d down", upCount, downCount)
	}

	// Determine overall status
	if downCount > 0 {
		return StatusDegraded, nil
	}

	return StatusOK, nil
}

// GetMetrics returns Prometheus health metrics in plain text format
func (c *HealthChecker) GetMetrics() (string, error) {
	status, err := c.Check()
	if err != nil {
		status = StatusError
	}

	// Convert status to numeric value for the gauge
	statusValue := 0
	switch status {
	case StatusOK:
		statusValue = 2
	case StatusDegraded:
		statusValue = 1
	case StatusError:
		statusValue = 0
	}

	metrics := fmt.Sprintf(`# HELP prometheus_health_status Health status of the Prometheus instance (0=error, 1=degraded, 2=ok)
# TYPE prometheus_health_status gauge
prometheus_health_status %d
`, statusValue)

	return metrics, nil
}
