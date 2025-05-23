package main

import (
    "os"
)

func main() {
    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}

// getenv returns the value of the environment variable key, or defaultValue if not set
func getenv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
