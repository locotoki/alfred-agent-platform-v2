package main

import (
    "context"
    "log"
    "path/filepath"

    "github.com/spf13/cobra"
    "alfred/internal/indexer"
)

func init() {
    rootCmd.AddCommand(ingestCmd)
    ingestCmd.Flags().StringP("path", "p", "./docs/**/*.md", "glob of documents to ingest")
    ingestCmd.Flags().IntP("batch", "b", 64, "batch size for upserts")
}

var ingestCmd = &cobra.Command{
    Use:   "ingest",
    Short: "Ingest local markdown/text files into the vector store",
    RunE: func(cmd *cobra.Command, _ []string) error {
        ctx := context.Background()
        pattern, _ := cmd.Flags().GetString("path")
        batch, _   := cmd.Flags().GetInt("batch")

        files, err := filepath.Glob(pattern)
        if err \!= nil {
            return err
        }
        if len(files) == 0 {
            log.Printf("No files matched pattern %q", pattern)
            return nil
        }

        idx, err := indexer.New(indexer.Config{
            ModelName: getenv("EMBED_MODEL", "text-embedding-3-small"),
            BatchSize: batch,
        })
        if err \!= nil {
            return err
        }
        return idx.Run(ctx, files)
    },
}
