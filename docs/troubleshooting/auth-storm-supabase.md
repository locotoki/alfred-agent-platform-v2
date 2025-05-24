# Supabase Realtime → Postgres authentication storm

**Date fixed:** 24 May 2025
**Symptom:** `db-postgres` CPU pegged at ~390 % while `db-realtime`
spammed failed logins for `supabase_admin`.

## Root cause
* The `supabase_admin` role existed **without a password** because the
  `migrations/supabase` bootstrap scripts never ran (missing directory
  mount).
* `db-realtime` tried that account, failed, retried aggressively, and
  saturated Postgres.

## Quick remediation applied
1. Switched **`db-realtime`** to use the existing `postgres` role
   (`docker-compose.yml → \`DB_USER: postgres\``).
2. Created the missing `migrations/supabase/` directory so future boots
   run the official Supabase SQL that assigns a password to
   `supabase_admin`.

## Long-term recommendation
* Either keep Realtime on `postgres` **or** create a proper
  password-bearing `supabase_admin` role and revert the env var.
* Add a Prometheus alert for `pg_authentication_failures_total > 0`.

---
*File generated automatically by o3 Architect sweep.*
