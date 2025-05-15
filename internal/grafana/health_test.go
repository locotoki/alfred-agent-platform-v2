package grafana

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestHealthChecker_Check(t *testing.T) {
	tests := []struct {
		name             string
		responseHealth   int
		responseHealthBody string
		datasourcesBody  string
		datasourcesHealthBody []string
		expectedStatus   HealthStatus
		expectedError    bool
		withAuth         bool
	}{
		{
			name:             "All systems healthy",
			responseHealth:   http.StatusOK,
			responseHealthBody: `{"database":"ok", "version":"10.4.3"}`,
			datasourcesBody:  `[{"id":1, "type":"prometheus"}, {"id":2, "type":"postgres"}]`,
			datasourcesHealthBody: []string{
				`{"status":"OK", "message":"Data source is working"}`,
				`{"status":"OK", "message":"Database connection OK"}`,
			},
			expectedStatus:   StatusOK,
			expectedError:    false,
		},
		{
			name:             "Grafana core down",
			responseHealth:   http.StatusInternalServerError,
			responseHealthBody: `{"error": "database error"}`,
			datasourcesBody:  `[]`,
			datasourcesHealthBody: []string{},
			expectedStatus:   StatusError,
			expectedError:    true,
		},
		{
			name:             "One datasource degraded",
			responseHealth:   http.StatusOK,
			responseHealthBody: `{"database":"ok", "version":"10.4.3"}`,
			datasourcesBody:  `[{"id":1, "type":"prometheus"}, {"id":2, "type":"postgres"}]`,
			datasourcesHealthBody: []string{
				`{"status":"OK", "message":"Data source is working"}`,
				`{"status":"ERROR", "message":"Database connection failed"}`,
			},
			expectedStatus:   StatusDegraded,
			expectedError:    false,
		},
		{
			name:             "Authentication required",
			responseHealth:   http.StatusUnauthorized,
			responseHealthBody: `{"message":"Unauthorized"}`,
			datasourcesBody:  `[]`,
			datasourcesHealthBody: []string{},
			expectedStatus:   StatusError,
			expectedError:    true,
			withAuth:         true,
		},
		{
			name:             "Schema tolerance",
			responseHealth:   http.StatusOK,
			responseHealthBody: `{"database":"ok", "services":{"database":"ok"}, "extra_field":"value"}`,
			datasourcesBody:  `[{"id":1, "name": "test", "type":"prometheus"}]`,
			datasourcesHealthBody: []string{
				`{"status":"OK", "details":{"message":"Data source is working"}}`,
			},
			expectedStatus:   StatusOK,
			expectedError:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mux := http.NewServeMux()

			// Setup health endpoint
			mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
				if tt.withAuth && r.Header.Get("Authorization") == "" {
					w.WriteHeader(http.StatusUnauthorized)
					_, err := w.Write([]byte(`{"message":"Unauthorized"}`))
					if err != nil {
						t.Fatal(err)
					}
					return
				}
				w.WriteHeader(tt.responseHealth)
				_, err := w.Write([]byte(tt.responseHealthBody))
				if err != nil {
					t.Fatal(err)
				}
			})

			// Setup datasources endpoint
			mux.HandleFunc("/api/datasources", func(w http.ResponseWriter, r *http.Request) {
				if tt.withAuth && r.Header.Get("Authorization") == "" {
					w.WriteHeader(http.StatusUnauthorized)
					_, err := w.Write([]byte(`{"message":"Unauthorized"}`))
					if err != nil {
						t.Fatal(err)
					}
					return
				}
				w.WriteHeader(http.StatusOK)
				_, err := w.Write([]byte(tt.datasourcesBody))
				if err != nil {
					t.Fatal(err)
				}
			})

			// Setup datasource health endpoints
			mux.HandleFunc("/api/datasources/", func(w http.ResponseWriter, r *http.Request) {
				if tt.withAuth && r.Header.Get("Authorization") == "" {
					w.WriteHeader(http.StatusUnauthorized)
					_, err := w.Write([]byte(`{"message":"Unauthorized"}`))
					if err != nil {
						t.Fatal(err)
					}
					return
				}

				parts := strings.Split(r.URL.Path, "/")
				if len(parts) < 4 || parts[3] == "" {
					w.WriteHeader(http.StatusNotFound)
					_, err := w.Write([]byte(`{"message":"Datasource not found"}`))
					if err != nil {
						t.Fatal(err)
					}
					return
				}

				dsID := parts[3]
				if dsID == "1" && len(tt.datasourcesHealthBody) > 0 {
					w.WriteHeader(http.StatusOK)
					_, err := w.Write([]byte(tt.datasourcesHealthBody[0]))
					if err != nil {
						t.Fatal(err)
					}
					return
				} else if dsID == "2" && len(tt.datasourcesHealthBody) > 1 {
					w.WriteHeader(http.StatusOK)
					_, err := w.Write([]byte(tt.datasourcesHealthBody[1]))
					if err != nil {
						t.Fatal(err)
					}
					return
				}

				w.WriteHeader(http.StatusNotFound)
				_, err := w.Write([]byte(`{"message":"Datasource not found"}`))
				if err != nil {
					t.Fatal(err)
				}
			})

			server := httptest.NewServer(mux)
			defer server.Close()

			checker := &HealthChecker{
				GrafanaURL: server.URL,
				Timeout:    time.Second * 5,
			}

			if tt.withAuth {
				checker.Auth = "admin:admin"
			}

			status, err := checker.Check()

			if (err != nil) != tt.expectedError {
				t.Errorf("Expected error: %v, got: %v, error: %v", tt.expectedError, err != nil, err)
			}

			if status != tt.expectedStatus {
				t.Errorf("Expected status: %v, got: %v", tt.expectedStatus, status)
			}
		})
	}
}

func TestHealthChecker_collectMetrics(t *testing.T) {
	// Initialize a test HTTP server
	mux := http.NewServeMux()

	// Setup health endpoint
	mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"database":"ok"}`))
	})

	// Setup datasources endpoint
	mux.HandleFunc("/api/datasources", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`[
			{"id":1, "type":"prometheus", "name":"Prometheus"},
			{"id":2, "type":"postgres", "name":"PostgreSQL"}
		]`))
	})

	// Setup datasource health endpoints
	mux.HandleFunc("/api/datasources/1/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"OK"}`))
	})

	mux.HandleFunc("/api/datasources/2/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"OK"}`))
	})

	server := httptest.NewServer(mux)
	defer server.Close()

	checker := &HealthChecker{
		GrafanaURL: server.URL,
		Timeout:    time.Second * 5,
	}

	// Reset metrics before test
	resetMetrics()

	// Collect metrics
	err := checker.collectMetrics()
	if err != nil {
		t.Fatalf("Error collecting metrics: %v", err)
	}

	// Verify metrics were collected
	if !containsMetric("grafana_datasource_up_total", t) {
		t.Error("Expected grafana_datasource_up_total metric to be present")
	}

	if !containsMetric("grafana_api_latency_seconds", t) {
		t.Error("Expected grafana_api_latency_seconds metric to be present")
	}
}

// Helper to check if a metric exists in the registry
func containsMetric(name string, t *testing.T) bool {
	metricJSON, err := getMetricsAsJSON()
	if err != nil {
		t.Fatalf("Error getting metrics as JSON: %v", err)
		return false
	}

	return strings.Contains(string(metricJSON), name)
}

func getMetricsAsJSON() ([]byte, error) {
	metrics := getPrometheusMetrics()
	return json.Marshal(metrics)
}