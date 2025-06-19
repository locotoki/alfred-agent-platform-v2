# Git Hooks Setup

## Post-Commit Hook

The `.githooks/post-commit` hook automatically indexes repository changes into Qdrant for memory services.

### Setup

To enable the post-commit hook in your local development environment:

```bash
# Symlink the hook into your .git/hooks directory
ln -sf ../../.githooks/post-commit .git/hooks/post-commit
```

### What it does

- Runs `scripts/git2mem.py` after each commit
- Indexes modified `.md`, `.py`, and `.yml` files into Qdrant
- Provides vector search capabilities for the agent memory system