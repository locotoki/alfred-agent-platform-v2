package main

import (
    "context"
    "log"
    "os"
    "path/filepath"

    "github.com/spf13/cobra"
    "github.com/jackc/pgx/v5/pgxpool"
    "alfred/internal/indexer"
    "alfred/internal/repo"
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

        // Connect to PostgreSQL
        pool, err := pgxpool.New(ctx, os.Getenv("POSTGRES_DSN"))
        if err != nil {
            log.Fatal(err)
        }
        defer pool.Close()

        // Create repository
        pgRepo := repo.NewPGRepo(pool)

        idx, err := indexer.New(indexer.Config{
            ModelName: getenv("EMBED_MODEL", "text-embedding-3-small"),
            BatchSize: batch,
            Repo:      pgRepo,  // passes the concrete PG implementation
        })
        if err != nil {
            return err
        }
        return idx.Run(ctx, files)
    },
}
