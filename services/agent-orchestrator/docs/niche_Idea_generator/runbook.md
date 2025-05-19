# Runbook

## Cron failure

1. Check GitHub Action “hot‑niches” run log
2. Re‑run job manually with:
   ```bash
   supabase functions invoke hotNiches
   ```

## UI cannot fetch /api/taxonomy/hot

* Likely Supabase RLS mis‑config → Verify anon role has `select`
