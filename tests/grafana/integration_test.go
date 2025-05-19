//go:build integration

package grafana_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

// Integration test for Grafana health probe
func TestGrafanaProbe_Integration(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test in short mode")
	}

	// Build the binary
	buildCmd := exec.Command("go", "build", "-o", "../../bin/grafana-probe", "../../cmd/grafana-probe/main.go")
	buildOutput, err := buildCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Failed to build binary: %v, output: %s", err, buildOutput)
	}

	// Ensure binary was built
	binaryPath, err := filepath.Abs("../../bin/grafana-probe")
	if err != nil {
		t.Fatalf("Failed to get absolute path to binary: %v", err)
	}
	if _, err := os.Stat(binaryPath); os.IsNotExist(err) {
		t.Fatalf("Binary was not built: %v", err)
	}

	// Start Grafana container
	ctx := context.Background()
	req := testcontainers.ContainerRequest{
		Image:        "grafana/grafana:10.4.3",
		ExposedPorts: []string{"3000/tcp"},
		Env: map[string]string{
			"GF_AUTH_ANONYMOUS_ENABLED":  "true",
			"GF_AUTH_ANONYMOUS_ORG_ROLE": "Admin",
			"GF_SECURITY_ADMIN_PASSWORD": "admin",
		},
		WaitingFor: wait.ForHTTP("/api/health").WithPort("3000/tcp"),
	}

	grafanaContainer, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		t.Fatalf("Failed to start Grafana container: %v", err)
	}
	defer grafanaContainer.Terminate(ctx)

	// Get the container IP and port
	ip, err := grafanaContainer.Host(ctx)
	if err != nil {
		t.Fatalf("Failed to get container IP: %v", err)
	}

	port, err := grafanaContainer.MappedPort(ctx, "3000/tcp")
	if err != nil {
		t.Fatalf("Failed to get mapped port: %v", err)
	}

	grafanaURL := fmt.Sprintf("http://%s:%s", ip, port.Port())

	// Wait for Grafana to be fully up and add a test datasource
	time.Sleep(5 * time.Second)
	if err := addTestDatasource(grafanaURL); err != nil {
		t.Fatalf("Failed to add test datasource: %v", err)
	}

	// Test cases
	testCases := []struct {
		name          string
		args          []string
		expectedCode  int
		expectedError bool
	}{
		{
			name:          "Basic health check",
			args:          []string{"--grafana", grafanaURL},
			expectedCode:  0,
			expectedError: false,
		},
		{
			name:          "With auth",
			args:          []string{"--grafana", grafanaURL, "--grafana-auth", "admin:admin"},
			expectedCode:  0,
			expectedError: false,
		},
		{
			name:          "Invalid URL",
			args:          []string{"--grafana", "http://invalid-url:3000"},
			expectedCode:  2,
			expectedError: true,
		},
		{
			name:          "Verbose mode",
			args:          []string{"--grafana", grafanaURL, "--verbose"},
			expectedCode:  0,
			expectedError: false,
		},
	}

	// Run test cases
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			cmd := exec.Command(binaryPath, tc.args...)
			var stdout, stderr bytes.Buffer
			cmd.Stdout = &stdout
			cmd.Stderr = &stderr

			err := cmd.Run()

			if tc.expectedError {
				if err == nil {
					t.Errorf("Expected error but got none")
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error: %v, stderr: %s", err, stderr.String())
				}
			}

			if exitCode := cmd.ProcessState.ExitCode(); exitCode != tc.expectedCode {
				t.Errorf("Expected exit code %d, got %d, stderr: %s", tc.expectedCode, exitCode, stderr.String())
			}
		})
	}
}

// addTestDatasource adds a test Prometheus datasource to Grafana
func addTestDatasource(grafanaURL string) error {
	datasource := map[string]interface{}{
		"name":      "Test Prometheus",
		"type":      "prometheus",
		"url":       "http://prometheus:9090",
		"access":    "proxy",
		"isDefault": true,
	}

	payload, err := json.Marshal(datasource)
	if err != nil {
		return fmt.Errorf("failed to marshal datasource: %v", err)
	}

	req, err := http.NewRequest("POST", grafanaURL+"/api/datasources", bytes.NewBuffer(payload))
	if err != nil {
		return fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth("admin", "admin")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to add datasource: %s, status: %d", string(body), resp.StatusCode)
	}

	return nil
}
