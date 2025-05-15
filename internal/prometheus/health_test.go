package prometheus

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestHealthChecker_Check(t *testing.T) {
	tests := []struct {
		name           string
		responseStatus int
		responseBody   string
		expectedStatus HealthStatus
		expectedError  bool
	}{
		{
			name:           "successful_response_all_up",
			responseStatus: http.StatusOK,
			responseBody:   `{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","instance":"service1:9090","job":"prometheus"},"value":[1620000000,"1"]},{"metric":{"__name__":"up","instance":"service2:9090","job":"prometheus"},"value":[1620000000,"1"]}]}}`,
			expectedStatus: StatusOK,
			expectedError:  false,
		},
		{
			name:           "successful_response_some_down",
			responseStatus: http.StatusOK,
			responseBody:   `{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","instance":"service1:9090","job":"prometheus"},"value":[1620000000,"1"]},{"metric":{"__name__":"up","instance":"service2:9090","job":"prometheus"},"value":[1620000000,"0"]}]}}`,
			expectedStatus: StatusDegraded,
			expectedError:  false,
		},
		{
			name:           "successful_response_no_targets",
			responseStatus: http.StatusOK,
			responseBody:   `{"status":"success","data":{"resultType":"vector","result":[]}}`,
			expectedStatus: StatusDegraded,
			expectedError:  false,
		},
		{
			name:           "prometheus_error_response",
			responseStatus: http.StatusOK,
			responseBody:   `{"status":"error","errorType":"execution_error","error":"query execution failed: invalid query"}`,
			expectedStatus: StatusError,
			expectedError:  true,
		},
		{
			name:           "http_error_response",
			responseStatus: http.StatusInternalServerError,
			responseBody:   `Internal Server Error`,
			expectedStatus: StatusError,
			expectedError:  true,
		},
		{
			name:           "invalid_json_response",
			responseStatus: http.StatusOK,
			responseBody:   `not a valid json`,
			expectedStatus: StatusError,
			expectedError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create test server
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(tt.responseStatus)
				w.Write([]byte(tt.responseBody))
			}))
			defer server.Close()

			// Create health checker with test server URL
			client := &http.Client{Timeout: 1 * time.Second}
			checker := NewHealthChecker(client, server.URL, false)

			// Perform health check
			status, err := checker.Check()

			// Check for expected error
			if (err != nil) != tt.expectedError {
				t.Errorf("error = %v, wantErr %v", err, tt.expectedError)
				return
			}

			// If no error is expected, check the status
			if !tt.expectedError && status != tt.expectedStatus {
				t.Errorf("status = %v, want %v", status, tt.expectedStatus)
			}
		})
	}
}

func TestHealthChecker_GetMetrics(t *testing.T) {
	tests := []struct {
		name           string
		responseStatus int
		responseBody   string
		wantedMetrics  string
		expectedError  bool
	}{
		{
			name:           "ok_status",
			responseStatus: http.StatusOK,
			responseBody:   `{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","instance":"service1:9090","job":"prometheus"},"value":[1620000000,"1"]}]}}`,
			wantedMetrics:  "prometheus_health_status 2",
			expectedError:  false,
		},
		{
			name:           "degraded_status",
			responseStatus: http.StatusOK,
			responseBody:   `{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","instance":"service1:9090","job":"prometheus"},"value":[1620000000,"0"]}]}}`,
			wantedMetrics:  "prometheus_health_status 1",
			expectedError:  false,
		},
		{
			name:           "error_status",
			responseStatus: http.StatusInternalServerError,
			responseBody:   `Internal Server Error`,
			wantedMetrics:  "prometheus_health_status 0",
			expectedError:  false, // GetMetrics should not return an error even if the check fails
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create test server
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(tt.responseStatus)
				w.Write([]byte(tt.responseBody))
			}))
			defer server.Close()

			// Create health checker with test server URL
			client := &http.Client{Timeout: 1 * time.Second}
			checker := NewHealthChecker(client, server.URL, false)

			// Get metrics
			metrics, err := checker.GetMetrics()

			// Check for expected error
			if (err != nil) != tt.expectedError {
				t.Errorf("error = %v, wantErr %v", err, tt.expectedError)
				return
			}

			// Check if metrics contain the expected status
			if !tt.expectedError && !containsSubstring(metrics, tt.wantedMetrics) {
				t.Errorf("metrics = %v, want to contain %v", metrics, tt.wantedMetrics)
			}
		})
	}
}

// Helper function to check if a string contains a substring
func containsSubstring(s, substr string) bool {
	return s != "" && substr != "" && s != substr && len(s) > len(substr) && s[len(s)-len(substr):] == substr
}