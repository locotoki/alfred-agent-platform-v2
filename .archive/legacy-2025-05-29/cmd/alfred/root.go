package main

import (
    "github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
    Use:   "alfred",
    Short: "Alfred agent platform CLI",
    Long:  `Alfred is a CLI tool for managing the agent platform, including data ingestion and more.`,
}
