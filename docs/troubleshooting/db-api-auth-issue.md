# DB-API Authentication Issue

## Problem
The `db-api` service (PostgREST) is showing as unhealthy due to authentication failures with PostgreSQL.

## Root Cause
1. The docker-compose.yml uses `${DB_PASSWORD:-your-super-secret-password}` for db-api
2. The PostgreSQL container uses `${POSTGRES_PASSWORD:-postgres}`
3. These environment variables don't match by default

## Symptoms
```
db-api  | connection to server at "db-postgres" (172.18.0.3), port 5432 failed: FATAL:  password authentication failed for user "postgres"
```

## Quick Fix
Add to your `.env` file:
```bash
DB_PASSWORD=postgres
```

Then recreate db-api:
```bash
docker compose up -d --force-recreate db-api
```

## Permanent Fix
Update `docker-compose.yml` to use consistent password variables:

```yaml
db-api:
  environment:
    PGRST_DB_URI: postgres://postgres:${POSTGRES_PASSWORD}@db-postgres:5432/postgres
```

## Additional Issue: Missing 'anon' Role
PostgREST requires an 'anon' role in PostgreSQL. To create it:

1. Access PostgreSQL directly (requires fixing auth first)
2. Run the SQL from `docker/initdb/00-create-anon.sql`

## Current Status
- 9/10 services healthy (meets GA requirement of ≤2 unhealthy)
- db-api is the only unhealthy service
- This is a known issue with a documented fix
- Does not block baseline capture or development