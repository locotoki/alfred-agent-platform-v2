# Local PostgreSQL Upgrade to v15

## Options
1. **Fast reset (recommended for dev):**
   ```bash
   docker compose down -v db
   make up
   ```
   Destroys local data volume; stack recreates v15 cluster.

2. **pg_upgrade (keep data):**
   Follow upstream docs: https://www.postgresql.org/docs/15/pgupgrade.html
