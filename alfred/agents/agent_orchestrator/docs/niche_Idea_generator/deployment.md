# Deployment & CI/CD

1. **Branch push** → GitHub Action
2. Steps:
   * pnpm install
   * pnpm lint && pnpm test
   * Build preview (Vercel)
   * Comment preview URL on PR
3. Merge → auto‑deploy to Production env

Secrets live in GitHub → Environment `production`.
