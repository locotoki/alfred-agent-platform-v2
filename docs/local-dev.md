# Local Development Guide

## Health Check Notes

Some containers lack curl/wget for health checks:
- **Qdrant** (vector-db): Removed health check, service accessible on :6333
- **Supabase Studio** (db-admin): Removed health check, UI accessible on :3001

Both services function normally despite missing health checks.

## Getting Started

1. Ensure Docker Desktop is installed and running
2. Copy `.env.template` to `.env` and fill in required values
3. Run `docker compose up -d` to start core services
4. Check service status with `docker compose ps`

## Service Endpoints

- PostgreSQL: localhost:5432
- Redis: localhost:6379
- Qdrant Vector DB: http://localhost:6333
- Supabase Studio: http://localhost:3001
- PostgREST API: http://localhost:3000
- Mail Server UI: http://localhost:8025