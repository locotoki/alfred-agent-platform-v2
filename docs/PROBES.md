# Health Check Probes

This document describes the health check probes available in the Alfred Agent Platform.

## Database Probes

Database probes verify the health and connectivity of database services by performing:
1. Connection validation
2. Ping operations
3. Read/write operations to a health check table

### Common Configuration

All database probes share common configuration options:

```
--db-type        Database type (postgres, mysql, sqlite, mssql)
--db-dsn         Database connection string
--once           Run health check once and exit
--interval       Interval between health checks (default: 60s)
--timeout        Timeout for health check operations (default: 10s)
--create-table   Create health check table if it doesn't exist (default: true)
```

### PostgreSQL Probe

Verifies connectivity to PostgreSQL databases.

Usage:
```
healthcheck --db-type postgres --db-dsn "user:password@host:port/dbname"
```

### MySQL Probe

Verifies connectivity to MySQL databases.

Usage:
```
healthcheck --db-type mysql --db-dsn "user:password@tcp(host:port)/dbname"
```

### SQLite Probe

Verifies connectivity to SQLite databases.

Usage:
```
healthcheck --db-type sqlite --db-dsn "path/to/database.db"
```

### MSSQL Probe

Verifies connectivity to Microsoft SQL Server databases.

Usage:
```
healthcheck --db-type mssql --db-dsn "user:password@host:port/dbname"
```

### Connection String Format

Each database type has its own connection string format:

| Database | Format | Example |
|----------|--------|---------|
| PostgreSQL | `user:password@host:port/dbname` | `alfred:secret@localhost:5432/alfred_db` |
| MySQL | `user:password@tcp(host:port)/dbname` | `alfred:secret@tcp(localhost:3306)/alfred_db` |
| SQLite | `path/to/database.db` | `/var/lib/alfred/data.db` |
| MSSQL | `user:password@host:port/dbname` | `sa:Password123!@localhost:1433/tempdb` |

## Service Probes

### Grafana Probe

Verifies the health of a Grafana service by checking:
1. API endpoint availability
2. Authentication
3. Dashboard availability

Usage:
```
grafana-probe --url http://localhost:3000 --api-key "eyJrIjoiT0tTcG1pUlY2RnVKZTFVaDFsNFZXdE9ZWmNrMkZYbk"
```

### Prometheus Probe

Verifies the health of a Prometheus service by checking:
1. API endpoint availability
2. Query execution capability
3. Alertmanager integration

Usage:
```
prometheus-probe --url http://localhost:9090
```

## Integration with Docker

Health check probes are integrated into service containers using the `HEALTHCHECK` instruction in Dockerfiles:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["healthcheck", "--db-type", "postgres", "--db-dsn", "${DB_DSN}", "--once"]
```

## Alert Rules

Alert rules are defined in YAML files in the `charts/alerts/` directory. They follow this format:

```yaml
groups:
 - name: service-name
   rules:
   - alert: ServiceHealthCritical
     expr: service_health{service="service-name"} == 0
     for: 5m
     labels: {severity: "critical"}
     annotations: {summary: "Service DOWN"}
```

## Metrics

All probes export these common metrics:

| Metric | Description |
|--------|-------------|
| `service_health` | Overall service health (0-1) |
| `db_connection_success` | Database connection success (0-1) |
| `db_connection_latency_seconds` | Database connection latency |
| `db_ping_success` | Database ping success (0-1) |
| `db_ping_latency_seconds` | Database ping latency |
| `db_read_success` | Database read success (0-1) |
| `db_read_latency_seconds` | Database read latency |
| `db_write_success` | Database write success (0-1) |
| `db_write_latency_seconds` | Database write latency |
