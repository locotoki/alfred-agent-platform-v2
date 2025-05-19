# Database Health Probe CLI Reference

This document outlines the command-line options available for the database health probe system in the Alfred Agent Platform v2.

## Overview

The database health probe CLI is integrated with the standard healthcheck binary (v0.4.0 or later) and provides options for monitoring the health of different database types.

## Common Options

| Option | Description | Default |
|--------|-------------|---------|
| `--export-metrics` | Export metrics to Prometheus endpoint | `true` |
| `--metrics-port` | Port to expose Prometheus metrics | `9091` |
| `--check-interval` | Interval between health checks (in seconds) | `15` |
| `--timeout` | Global timeout for health check operations (in seconds) | `5` |
| `--create-tables` | Create health check tables if they don't exist | `true` |
| `--verbosity` | Log verbosity level (debug, info, warn, error) | `info` |

## Database-Specific Options

### PostgreSQL

```bash
healthcheck --postgres-dsn="postgres://user:pass@host:5432/dbname" \
  --export-metrics \
  --metrics-port=9091
```

### MySQL

```bash
healthcheck --mysql-dsn="mysql://user:pass@tcp(host:3306)/db" \
  --export-metrics \
  --metrics-port=9091
```

### SQLite

```bash
healthcheck --sqlite-dsn="file:/data/app.db?_pragma=journal_mode(WAL)" \
  --export-metrics \
  --metrics-port=9091
```

### MSSQL (coming soon)

```bash
healthcheck --mssql-dsn="sqlserver://user:pass@host:1433/db" \
  --export-metrics \
  --metrics-port=9091
```

## Configuration Options

### Connection Pooling

| Option | Description | Default |
|--------|-------------|---------|
| `--max-open-conns` | Maximum number of open connections | `10` |
| `--max-idle-conns` | Maximum number of idle connections | `5` |
| `--conn-max-lifetime` | Maximum lifetime of connections (in minutes) | `5` |
| `--conn-max-idle-time` | Maximum idle time of connections (in minutes) | `5` |

### Timeouts

| Option | Description | Default |
|--------|-------------|---------|
| `--connect-timeout` | Maximum time for connecting to the database (in seconds) | `5` |
| `--read-timeout` | Maximum time for read operations (in seconds) | `2` |
| `--write-timeout` | Maximum time for write operations (in seconds) | `2` |
| `--ping-timeout` | Maximum time for ping operations (in seconds) | `1` |

### Retry Settings

| Option | Description | Default |
|--------|-------------|---------|
| `--max-retries` | Maximum number of retry attempts | `3` |
| `--retry-interval` | Interval between retries (in milliseconds) | `500` |

## DSN Formats

The Data Source Name (DSN) format depends on the database type:

### PostgreSQL DSN

```
postgres://[user[:password]@][host][:port][/dbname][?param1=value1&...]
```

Example:
```
postgres://myuser:mypassword@localhost:5432/mydb?sslmode=disable
```

### MySQL DSN

```
mysql://[user[:password]@][tcp|unix](host[:port])[/dbname][?param1=value1&...]
```

Example:
```
mysql://myuser:mypassword@tcp(localhost:3306)/mydb?parseTime=true
```

### SQLite DSN

```
file:path/to/file[?param1=value1&...]
```

Example:
```
file:/data/app.db?_pragma=journal_mode(WAL)&_pragma=foreign_keys(ON)
```

### MSSQL DSN

```
sqlserver://[user[:password]@][host][:port][?database=dbname&param1=value1&...]
```

Example:
```
sqlserver://sa:mypassword@localhost:1433?database=mydb
```

## Metrics

The database health probe exports the following metrics to Prometheus:

- `service_health` - Overall health status (1.0=up, 0.5=degraded, 0.0=down)
- `db_connection_success` - Connection success (1=success, 0=failure)
- `db_ping_success` - Ping success (1=success, 0=failure)
- `db_read_success` - Read operation success (1=success, 0=failure)
- `db_write_success` - Write operation success (1=success, 0=failure)
- `db_connection_latency_seconds` - Database connection latency
- `db_ping_latency_seconds` - Database ping latency
- `db_read_latency_seconds` - Database read operation latency
- `db_write_latency_seconds` - Database write operation latency
- `db_driver_type` - Database driver type (1=Postgres, 2=MySQL, 3=SQLite, 4=MSSQL)

## Example Usage

### Basic Usage

```bash
# Start PostgreSQL monitoring
healthcheck --postgres-dsn="postgres://user:pass@localhost:5432/mydb"

# Start MySQL monitoring
healthcheck --mysql-dsn="mysql://user:pass@tcp(localhost:3306)/mydb"

# Start SQLite monitoring
healthcheck --sqlite-dsn="file:/data/app.db"
```

### Advanced Usage

```bash
# Custom connection settings for PostgreSQL
healthcheck --postgres-dsn="postgres://user:pass@localhost:5432/mydb" \
  --max-open-conns=20 \
  --max-idle-conns=10 \
  --conn-max-lifetime=10 \
  --check-interval=30 \
  --export-metrics \
  --metrics-port=9091 \
  --verbosity=debug
```

### Docker Integration

```bash
# Example docker run command
docker run -d \
  -p 5432:5432 \
  -p 9091:9091 \
  --name postgres-health \
  --health-cmd="healthcheck --postgres-dsn=\"postgres://postgres:postgres@localhost:5432/postgres\" --ping-only" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  my-postgres-image
```

## Troubleshooting

Common error codes and solutions:

- `ERROR: failed to connect to database`: Check DSN, network connectivity, and credentials
- `ERROR: read/write test failed`: Check database permissions and table creation rights
- `ERROR: metrics endpoint failed to start`: Check if port is already in use
- `WARNING: high database latency detected`: Check database performance and connection pool settings

For more detailed troubleshooting, set `--verbosity=debug` to see verbose output.

## Further Information

- [Database Health Probe Design](./DB_PROBE_DESIGN.md)
- [Health Check Implementation Guide](../HEALTH_CHECK_IMPLEMENTATION_GUIDE.md)
- [Monitoring Infrastructure](../operations/monitoring/monitoring-infrastructure.md)
