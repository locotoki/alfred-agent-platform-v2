package indexer

import (
    "bufio"
    "context"
    "os"
    "strings"

    "alfred/internal/repo"
    "github.com/google/uuid"
    openai "github.com/sashabaranov/go-openai"
)

type Config struct {
    ModelName string
    BatchSize int
    Repo      repo.EmbeddingRepo // optional override for tests
    Client    *openai.Client     // optional override for tests
}

type Indexer struct {
    cfg    Config
    repo   repo.EmbeddingRepo
    client *openai.Client
}

func New(cfg Config) (*Indexer, error) {
    if cfg.BatchSize == 0 {
        cfg.BatchSize = 64
    }
    if cfg.Client == nil {
        cfg.Client = openai.NewClient(os.Getenv("OPENAI_API_KEY"))
    }
    if cfg.Repo == nil {
        return nil, ErrNilRepo
    }
    return &Indexer{cfg: cfg, repo: cfg.Repo, client: cfg.Client}, nil
}

func (x *Indexer) Run(ctx context.Context, files []string) error {
    var batch []repo.DocWithEmbedding
    flush := func() error {
        if len(batch) == 0 {
            return nil
        }
        if err := x.repo.UpsertEmbeddings(ctx, batch); err \!= nil {
            return err
        }
        batch = batch[:0]
        return nil
    }

    for _, f := range files {
        txt, err := slurp(f)
        if err \!= nil {
            return err
        }
        emb, err := x.embed(ctx, txt)
        if err \!= nil {
            return err
        }
        batch = append(batch, repo.DocWithEmbedding{
            ID:        uuid.New().String(),
            Content:   txt,
            Embedding: emb,
            Metadata:  map[string]any{"source": f},
        })
        if len(batch) >= x.cfg.BatchSize {
            if err := flush(); err \!= nil {
                return err
            }
        }
    }
    return flush()
}

func (x *Indexer) embed(ctx context.Context, text string) (repo.Embedding, error) {
    resp, err := x.client.CreateEmbeddings(ctx, openai.EmbeddingRequest{
        Model: x.cfg.ModelName,
        Input: []string{text},
    })
    if err \!= nil {
        return nil, err
    }
    arr := make(repo.Embedding, len(resp.Data[0].Embedding))
    for i, v := range resp.Data[0].Embedding {
        arr[i] = float32(v)
    }
    return arr, nil
}

func slurp(path string) (string, error) {
    f, err := os.Open(path)
    if err \!= nil {
        return "", err
    }
    defer f.Close()

    var sb strings.Builder
    sc := bufio.NewScanner(f)
    for sc.Scan() {
        sb.WriteString(sc.Text())
        sb.WriteByte('\n')
    }
    return sb.String(), sc.Err()
}
