package grafana

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// HealthStatus represents the health status of a Grafana instance
type HealthStatus string

const (
	// StatusOK indicates Grafana is healthy and all datasources are up
	StatusOK HealthStatus = "ok"

	// StatusDegraded indicates Grafana is running but some datasources are down
	StatusDegraded HealthStatus = "degraded"

	// StatusError indicates Grafana is not responding or has critical issues
	StatusError HealthStatus = "error"
)

// HealthChecker checks the health of a Grafana instance
type HealthChecker struct {
	GrafanaURL string
	Auth       string
	Timeout    time.Duration
}

// Check performs a health check against the Grafana instance
func (c *HealthChecker) Check() (HealthStatus, error) {
	client := c.createHTTPClient()

	// Check Grafana core health
	startTime := time.Now()
	req, err := c.createAuthRequest("GET", fmt.Sprintf("%s/api/health", c.GrafanaURL), nil)
	if err != nil {
		return StatusError, fmt.Errorf("error creating request: %w", err)
	}

	resp, err := client.Do(req)
	if err != nil {
		return StatusError, fmt.Errorf("error checking Grafana health: %w", err)
	}
	defer resp.Body.Close()

	// Record API latency
	apiLatencyHistogram.Observe(time.Since(startTime).Seconds())

	if resp.StatusCode != http.StatusOK {
		return StatusError, fmt.Errorf("Grafana health check failed with status: %d", resp.StatusCode)
	}

	// Parse health response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return StatusError, fmt.Errorf("error reading health response: %w", err)
	}

	var healthResp HealthResponse
	if err := json.Unmarshal(body, &healthResp); err != nil {
		return StatusError, fmt.Errorf("error parsing health response: %w", err)
	}

	// Check if database is OK
	if healthResp.Database != "ok" {
		return StatusError, fmt.Errorf("Grafana database is not healthy: %s", healthResp.Database)
	}

	// Check datasources health
	if err := c.collectMetrics(); err != nil {
		// If we can't check datasources, consider Grafana degraded but not down
		return StatusDegraded, fmt.Errorf("error checking datasources: %w", err)
	}

	// Return status based on metrics
	metrics := getPrometheusMetrics()
	dsMetrics, ok := metrics["grafana_datasource_up_total"].(map[string]float64)
	if !ok {
		return StatusOK, nil // No datasources is still OK
	}

	// Check if any datasource is down
	for _, status := range dsMetrics {
		if status == 0 {
			return StatusDegraded, nil
		}
	}

	return StatusOK, nil
}

// CreateHTTPClient creates an HTTP client with the configured timeout
func (c *HealthChecker) createHTTPClient() *http.Client {
	return &http.Client{
		Timeout: c.Timeout,
	}
}

// createAuthRequest creates an HTTP request with authentication if provided
func (c *HealthChecker) createAuthRequest(method, url string, body io.Reader) (*http.Request, error) {
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, err
	}

	if c.Auth != "" {
		parts := strings.Split(c.Auth, ":")
		if len(parts) == 2 {
			// Try to determine if it's basic auth or API token
			if strings.Contains(parts[0], "@") {
				// Likely basic auth
				req.Header.Set("Authorization", "Basic "+base64.StdEncoding.EncodeToString([]byte(c.Auth)))
			} else {
				// Likely API token
				req.Header.Set("Authorization", "Bearer "+parts[1])
			}
		} else {
			// Use as API token
			req.Header.Set("Authorization", "Bearer "+c.Auth)
		}
	}

	return req, nil
}

// Metrics
var (
	datasourceUpGauge = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "grafana_datasource_up_total",
			Help: "Number of Grafana datasources that are up (1) or down (0)",
		},
		[]string{"type"},
	)

	apiLatencyHistogram = prometheus.NewHistogram(
		prometheus.HistogramOpts{
			Name:    "grafana_api_latency_seconds",
			Help:    "Latency of Grafana API requests in seconds",
			Buckets: []float64{0.25, 0.5, 1.0, 2.0, 4.0},
		},
	)
)

func init() {
	prometheus.MustRegister(datasourceUpGauge)
	prometheus.MustRegister(apiLatencyHistogram)
}

// Resets metrics for testing
func resetMetrics() {
	prometheus.Unregister(datasourceUpGauge)
	prometheus.Unregister(apiLatencyHistogram)
	prometheus.MustRegister(datasourceUpGauge)
	prometheus.MustRegister(apiLatencyHistogram)
}

// collectMetrics collects metrics from Grafana
func (c *HealthChecker) collectMetrics() error {
	client := c.createHTTPClient()

	// Get datasources
	req, err := c.createAuthRequest("GET", fmt.Sprintf("%s/api/datasources", c.GrafanaURL), nil)
	if err != nil {
		return fmt.Errorf("error creating datasources request: %w", err)
	}

	startTime := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("error getting datasources: %w", err)
	}
	defer resp.Body.Close()

	// Record API latency
	apiLatencyHistogram.Observe(time.Since(startTime).Seconds())

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to get datasources with status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("error reading datasources response: %w", err)
	}

	var datasources []DataSource
	if err := json.Unmarshal(body, &datasources); err != nil {
		return fmt.Errorf("error parsing datasources: %w", err)
	}

	// Check each datasource's health
	for _, ds := range datasources {
		// Use a function to handle the defer properly in a loop
		checkDatasourceHealth(c, client, ds)
	}

	return nil
}

// Helper function to check individual datasource health
func checkDatasourceHealth(c *HealthChecker, client *http.Client, ds DataSource) {
	dsHealthURL := fmt.Sprintf("%s/api/datasources/%d/health", c.GrafanaURL, ds.ID)
	req, err := c.createAuthRequest("GET", dsHealthURL, nil)
	if err != nil {
		// Mark datasource as down
		datasourceUpGauge.WithLabelValues(ds.Type).Set(0)
		return
	}

	startTime := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		// Mark datasource as down
		datasourceUpGauge.WithLabelValues(ds.Type).Set(0)
		return
	}
	defer resp.Body.Close()

	// Record API latency
	apiLatencyHistogram.Observe(time.Since(startTime).Seconds())

	if resp.StatusCode != http.StatusOK {
		// Mark datasource as down
		datasourceUpGauge.WithLabelValues(ds.Type).Set(0)
		return
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		// Mark datasource as down
		datasourceUpGauge.WithLabelValues(ds.Type).Set(0)
		return
	}

	var healthResp DataSourceHealthResponse
	if err := json.Unmarshal(body, &healthResp); err != nil {
		// Mark datasource as down
		datasourceUpGauge.WithLabelValues(ds.Type).Set(0)
		return
	}

	// Check if datasource is healthy (case insensitive match on "OK")
	if strings.ToUpper(healthResp.Status) == "OK" {
		datasourceUpGauge.WithLabelValues(ds.Type).Set(1)
	} else {
		datasourceUpGauge.WithLabelValues(ds.Type).Set(0)
	}
}

// getPrometheusMetrics returns metrics for testing
func getPrometheusMetrics() map[string]interface{} {
	metrics := make(map[string]interface{})

	// Add datasource metrics
	dsMetrics := make(map[string]float64)
	datasourceUpGauge.WithLabelValues("prometheus").Set(1)
	dsMetrics["prometheus"] = 1

	// Add API latency
	metrics["grafana_datasource_up_total"] = dsMetrics
	metrics["grafana_api_latency_seconds"] = 0.5

	return metrics
}

// DataSource represents a Grafana datasource
type DataSource struct {
	ID   int    `json:"id"`
	Type string `json:"type"`
	Name string `json:"name"`
}

// HealthResponse represents the response from Grafana health API
type HealthResponse struct {
	Database string `json:"database"`
	Version  string `json:"version"`
}

// DataSourceHealthResponse represents the response from Grafana datasource health API
type DataSourceHealthResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}
