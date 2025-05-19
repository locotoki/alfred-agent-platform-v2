//go:build integration

package prometheus_test

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"testing"
)

func TestPrometheusProbe_Integration(t *testing.T) {
	// Skip integration tests if not explicitly enabled
	if os.Getenv("RUN_INTEGRATION_TESTS") != "1" {
		t.Skip("Skipping integration tests. Set RUN_INTEGRATION_TESTS=1 to enable.")
	}

	tests := []struct {
		name         string
		responseBody string
		wantExitCode int
	}{
		{
			name:         "all_targets_up",
			responseBody: `{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","instance":"service1:9090","job":"prometheus"},"value":[1620000000,"1"]}]}}`,
			wantExitCode: 0, // Success
		},
		{
			name:         "some_targets_down",
			responseBody: `{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"up","instance":"service1:9090","job":"prometheus"},"value":[1620000000,"1"]},{"metric":{"__name__":"up","instance":"service2:9090","job":"prometheus"},"value":[1620000000,"0"]}]}}`,
			wantExitCode: 1, // Degraded
		},
		{
			name:         "prometheus_error",
			responseBody: `{"status":"error","errorType":"execution_error","error":"query execution failed: invalid query"}`,
			wantExitCode: 2, // Error
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create a test server to mock Prometheus API
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Content-Type", "application/json")
				fmt.Fprintln(w, tt.responseBody)
			}))
			defer server.Close()

			// Build the binary (skip this if the binary is already built)
			buildCmd := exec.Command("go", "build", "-o", "/tmp/prometheus-probe", "../../cmd/prometheus-probe/main.go")
			if err := buildCmd.Run(); err != nil {
				t.Fatalf("Failed to build binary: %v", err)
			}

			// Run the binary with the test server URL
			cmd := exec.Command("/tmp/prometheus-probe", "--prometheus", "--prometheus-url", server.URL)
			err := cmd.Run()

			// Check the exit code
			exitCode := 0
			if err != nil {
				if exitErr, ok := err.(*exec.ExitError); ok {
					exitCode = exitErr.ExitCode()
				} else {
					t.Fatalf("Failed to run binary: %v", err)
				}
			}

			if exitCode != tt.wantExitCode {
				t.Errorf("Exit code = %d, want %d", exitCode, tt.wantExitCode)
			}
		})
	}
}
