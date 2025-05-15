# Database Metrics Implementation Guide

This guide outlines the implementation of standardized health checks and metrics exporters for database services in the Alfred Agent Platform v2.

## Overview

Database services present unique challenges for health monitoring due to their:
1. Different connectivity methods (HTTP, TCP, etc.)
2. Varying health check capabilities
3. Importance for overall platform stability

This guide provides a standardized approach to implementing metrics exporters specifically for database services.

## Metrics Exporter Design

The database metrics exporter is a lightweight application that:
1. Monitors database health status using appropriate connection methods
2. Exports standard Prometheus metrics on port 9091
3. Follows the established health check standard
4. Runs alongside database services without impacting performance

### Architecture

```
┌─────────────────┐     ┌────────────────┐     ┌───────────────┐
│                 │     │                │     │               │
│  Database       │◄────┤  DB Metrics    │◄────┤  Prometheus   │
│  Service        │     │  Exporter      │     │               │
│                 │     │                │     │               │
└─────────────────┘     └────────────────┘     └───────────────┘
                                ▲
                                │
                         ┌──────┴───────┐
                         │              │
                         │   Grafana    │
                         │              │
                         └──────────────┘
```

### Implementation by Database Type

#### PostgreSQL Database

For PostgreSQL (db-postgres), we'll use:
- TCP connectivity check for basic health
- SQL query execution test for deeper health validation
- Connection pool metrics
- Query performance metrics

```python
import psycopg2
from prometheus_client import start_http_server, Gauge, Counter

# Define metrics
pg_up = Gauge('postgres_up', 'PostgreSQL database availability')
pg_connections = Gauge('postgres_connections', 'Current number of connections')
pg_max_connections = Gauge('postgres_max_connections', 'Maximum allowed connections')
pg_queries_total = Counter('postgres_queries_total', 'Total number of queries executed')
pg_query_duration = Gauge('postgres_query_duration_seconds', 'Query execution time in seconds')

# Health check function
def check_postgres_health(dsn):
    try:
        # Basic connectivity check
        conn = psycopg2.connect(dsn)
        cursor = conn.cursor()
        
        # Connection pool metrics
        cursor.execute("SELECT count(*) FROM pg_stat_activity")
        connections = cursor.fetchone()[0]
        pg_connections.set(connections)
        
        cursor.execute("SHOW max_connections")
        max_conn = cursor.fetchone()[0]
        pg_max_connections.set(int(max_conn))
        
        # Simple query test for health validation
        start_time = time.time()
        cursor.execute("SELECT 1")
        end_time = time.time()
        pg_query_duration.set(end_time - start_time)
        pg_queries_total.inc()
        
        cursor.close()
        conn.close()
        
        # Database is up
        pg_up.set(1)
        return True
        
    except Exception as e:
        pg_up.set(0)
        return False
```

#### Redis Database

For Redis (redis), we'll use:
- PING command for basic health check
- INFO command for detailed metrics
- Key count and memory metrics

```python
import redis
from prometheus_client import start_http_server, Gauge, Counter

# Define metrics
redis_up = Gauge('redis_up', 'Redis availability')
redis_memory_used = Gauge('redis_memory_used_bytes', 'Redis memory usage in bytes')
redis_clients = Gauge('redis_connected_clients', 'Number of client connections')
redis_commands_total = Counter('redis_commands_total', 'Total number of commands processed')

# Health check function
def check_redis_health(host, port):
    try:
        client = redis.Redis(host=host, port=port)
        
        # Basic health check
        if client.ping():
            redis_up.set(1)
            
            # Get detailed info
            info = client.info()
            
            # Update metrics
            redis_memory_used.set(info.get('used_memory', 0))
            redis_clients.set(info.get('connected_clients', 0))
            redis_commands_total._value.set(info.get('total_commands_processed', 0))
            
            return True
        else:
            redis_up.set(0)
            return False
            
    except Exception as e:
        redis_up.set(0)
        return False
```

### HTTP API Services

For HTTP-based database services (db-api, db-auth, db-admin), we'll use:
- HTTP health check (/health or /healthz endpoints)
- Response time metrics
- Connection pool metrics where available

```python
import requests
import time
from prometheus_client import start_http_server, Gauge, Counter, Histogram

# Define metrics
service_up = Gauge('service_up', 'Service availability', ['service'])
http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['service', 'endpoint'])
http_request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration in seconds', ['service', 'endpoint'])

# Health check function
def check_http_health(service_name, url):
    start_time = time.time()
    try:
        response = requests.get(f"{url}/health", timeout=5)
        http_requests_total.labels(service=service_name, endpoint='/health').inc()
        
        duration = time.time() - start_time
        http_request_duration.labels(service=service_name, endpoint='/health').observe(duration)
        
        if response.status_code == 200:
            service_up.labels(service=service_name).set(1)
            return True
        else:
            service_up.labels(service=service_name).set(0)
            return False
            
    except Exception as e:
        duration = time.time() - start_time
        http_request_duration.labels(service=service_name, endpoint='/health').observe(duration)
        service_up.labels(service=service_name).set(0)
        return False
```

## DB Metrics Exporter Implementation

### 1. Service Architecture

Create a dedicated Python service (`db-metrics`) to handle metrics for all database services:

```python
import time
import threading
from prometheus_client import start_http_server, REGISTRY, Gauge, Counter
from fastapi import FastAPI, Response

# Create FastAPI app
app = FastAPI(title="DB Metrics Exporter")

# Define service metrics
service_health = Gauge('service_health', 'Service health status (1=up, 0=down)', ['service'])
service_info = Gauge('service_info', 'Service information', ['service', 'version'])
service_requests_total = Counter('service_requests_total', 'Total requests')

# Service configurations
services = {
    "db-postgres": {
        "type": "postgres",
        "dsn": "postgres://postgres:password@db-postgres:5432/postgres",
        "version": "1.0.0"
    },
    "db-api": {
        "type": "http",
        "url": "http://db-api:3000",
        "version": "1.0.0"
    },
    "db-auth": {
        "type": "http",
        "url": "http://db-auth:9999",
        "version": "1.0.0"
    },
    "db-admin": {
        "type": "http",
        "url": "http://db-admin:3000",
        "version": "1.0.0"
    },
    "db-realtime": {
        "type": "tcp",
        "host": "db-realtime",
        "port": 4000,
        "version": "1.0.0"
    },
    "db-storage": {
        "type": "http",
        "url": "http://db-storage:5000",
        "version": "1.0.0"
    },
    "redis": {
        "type": "redis",
        "host": "redis",
        "port": 6379,
        "version": "1.0.0"
    }
}

# Initialize service info metrics
for service_name, config in services.items():
    service_info.labels(service=service_name, version=config['version']).set(1)

# Health check implementations for each service type
def check_postgres_health(config):
    # Implementation as above...
    pass

def check_redis_health(config):
    # Implementation as above...
    pass

def check_http_health(service_name, config):
    # Implementation as above...
    pass

def check_tcp_health(service_name, config):
    # Implementation...
    pass

# Background monitoring thread
def monitoring_thread():
    while True:
        for service_name, config in services.items():
            try:
                if config['type'] == 'postgres':
                    is_healthy = check_postgres_health(config)
                elif config['type'] == 'redis':
                    is_healthy = check_redis_health(config)
                elif config['type'] == 'http':
                    is_healthy = check_http_health(service_name, config)
                elif config['type'] == 'tcp':
                    is_healthy = check_tcp_health(service_name, config)
                else:
                    is_healthy = False
                
                service_health.labels(service=service_name).set(1 if is_healthy else 0)
            except Exception as e:
                print(f"Error checking {service_name}: {str(e)}")
                service_health.labels(service=service_name).set(0)
        
        # Check every 15 seconds
        time.sleep(15)

# Start background thread
threading.Thread(target=monitoring_thread, daemon=True).start()

# Standard health endpoints
@app.get("/health")
async def health():
    service_requests_total.inc()
    services_status = {}
    
    for service_name in services:
        health_value = service_health.labels(service=service_name)._value.get()
        services_status[service_name] = "ok" if health_value == 1 else "error"
    
    overall_status = "ok" if all(status == "ok" for status in services_status.values()) else "degraded"
    
    return {
        "status": overall_status,
        "version": "1.0.0",
        "services": services_status
    }

@app.get("/healthz")
async def healthz():
    service_requests_total.inc()
    return {"status": "ok"}

@app.get("/metrics")
async def metrics():
    service_requests_total.inc()
    return Response(content=REGISTRY.generate_latest(), media_type="text/plain")

# Start metrics server
if __name__ == "__main__":
    # Start Prometheus metrics server
    start_http_server(9091)
    
    # Start FastAPI app
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### 2. Docker Implementation

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py /app/

# Expose ports for API and metrics
EXPOSE 8000
EXPOSE 9091

# Run the application
CMD ["python", "app.py"]
```

### 3. Docker Compose Configuration

```yaml
# db-metrics service in docker-compose.yml
db-metrics:
  build:
    context: ./services/db-metrics
    dockerfile: Dockerfile
  image: db-metrics:latest
  container_name: db-metrics
  ports:
    - "9120:8000"  # API port
    - "9121:9091"  # Metrics port
  depends_on:
    - db-postgres
    - db-api
    - db-auth
    - db-admin
    - db-realtime
    - db-storage
    - redis
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/healthz"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 45s
  restart: unless-stopped
  networks:
    - alfred-network
  labels:
    com.docker.compose.project: "alfred"
    com.docker.compose.group: "monitoring"
    com.docker.compose.service: "db-metrics"
```

### 4. Prometheus Configuration

```yaml
# Add to prometheus.yml
scrape_configs:
  # Other jobs...
  
  - job_name: 'db-metrics'
    static_configs:
      - targets: ['db-metrics:9091']
    metrics_path: '/metrics'
```

## Implementation Steps

1. Create the `db-metrics` service directory:
   ```bash
   mkdir -p services/db-metrics
   ```

2. Create the required files:
   ```bash
   touch services/db-metrics/app.py
   touch services/db-metrics/requirements.txt
   touch services/db-metrics/Dockerfile
   ```

3. Add dependencies to `requirements.txt`:
   ```
   fastapi==0.95.1
   uvicorn==0.22.0
   prometheus-client==0.16.0
   requests==2.29.0
   psycopg2-binary==2.9.6
   redis==4.5.4
   ```

4. Implement the `app.py` code as shown above

5. Build and deploy the service:
   ```bash
   docker-compose -f docker-compose-clean.yml build db-metrics
   docker-compose -f docker-compose-clean.yml up -d db-metrics
   ```

6. Update Prometheus configuration to include the new metrics

## Validation

1. Check the metrics endpoint:
   ```bash
   curl http://localhost:9121/metrics
   ```

2. Verify metrics in Prometheus:
   - Open http://localhost:9090 in a browser
   - Query for `service_health` metric
   - Check that all database services are reporting status

3. Create a Grafana dashboard:
   - Add a DB Health panel showing status of all database services
   - Add query performance metrics panels
   - Add connection pool utilization panels

## Next Steps

1. Add more detailed database-specific metrics
2. Implement alerts for database service degradation
3. Add database latency and performance metrics
4. Create detailed database health dashboards in Grafana