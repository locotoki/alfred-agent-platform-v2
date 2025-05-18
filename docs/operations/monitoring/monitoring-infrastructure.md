# Monitoring Infrastructure

*Last Updated: 2025-05-13*
*Owner: Infrastructure Team*
*Status: Active*

## Overview

This document describes the monitoring infrastructure for the Alfred Agent Platform v2. The platform uses a comprehensive monitoring stack to ensure high availability, performance, and reliability of all components. The monitoring infrastructure provides real-time visibility into the health, performance, and usage of the platform's services, enabling proactive issue detection and resolution.

## Architecture

The monitoring infrastructure follows a multi-layered approach to collect, process, store, and visualize metrics and logs from all platform components:

```mermaid
graph TD
    subgraph "Application Instrumentation"
        AppMetrics["Application Metrics"]
        LibMetrics["Library Metrics"]
        LogOutput["Log Output"]
    end

    subgraph "Collection Layer"
        NodeExporter["Node Exporter"]
        PostgresExporter["Postgres Exporter"]
        RedisExporter["Redis Exporter"]
        FluentBit["Fluent Bit"]
    end

    subgraph "Processing Layer"
        Prometheus["Prometheus"]
        AlertManager["Alert Manager"]
        Loki["Loki"]
    end

    subgraph "Visualization Layer"
        Grafana["Grafana"]
        GrafanaAlerts["Grafana Alerting"]
    end

    subgraph "Notification Layer"
        Email["Email"]
        Slack["Slack"]
        PagerDuty["PagerDuty"]
    end

    AppMetrics -->|Expose /metrics| Prometheus
    LibMetrics -->|Expose /metrics| Prometheus
    LogOutput -->|Forward logs| FluentBit

    NodeExporter -->|System metrics| Prometheus
    PostgresExporter -->|Database metrics| Prometheus
    RedisExporter -->|Cache metrics| Prometheus
    FluentBit -->|Forward logs| Loki

    Prometheus -->|Store metrics| Prometheus
    Prometheus -->|Alert rules| AlertManager
    Loki -->|Store logs| Loki

    Prometheus -->|Query metrics| Grafana
    Loki -->|Query logs| Grafana
    AlertManager -->|Alert notifications| GrafanaAlerts

    GrafanaAlerts -->|Send notifications| Email
    GrafanaAlerts -->|Send notifications| Slack
    GrafanaAlerts -->|Send notifications| PagerDuty
```

## Components

### Collection Layer

The collection layer is responsible for gathering metrics and logs from various sources:

#### Node Exporter

Node Exporter collects system-level metrics from all hosts:

```yaml
# docker-compose.yml (simplified)
monitoring-node:
  image: prom/node-exporter:v1.7.0
  container_name: monitoring-node
  ports:
    - "9100:9100"
  volumes:
    - /proc:/host/proc:ro
    - /sys:/host/sys:ro
    - /:/rootfs:ro
  command:
    - '--path.procfs=/host/proc'
    - '--path.sysfs=/host/sys'
    - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
  restart: unless-stopped
  networks:
    - alfred-network
```

Key metrics collected:
- CPU usage (user, system, idle, iowait)
- Memory usage (used, free, cached, buffers)
- Disk usage and I/O statistics
- Network traffic and connection states
- System load and process counts

#### Postgres Exporter

Postgres Exporter collects metrics from PostgreSQL databases:

```yaml
# docker-compose.yml (simplified)
monitoring-db:
  image: prometheuscommunity/postgres-exporter:v0.15.0
  container_name: monitoring-db
  ports:
    - "9187:9187"
  environment:
    DATA_SOURCE_NAME: "postgresql://user:password@db-postgres:5432/postgres?sslmode=disable"
  restart: unless-stopped
  networks:
    - alfred-network
```

Key metrics collected:
- Database connections (active, idle, max)
- Query execution statistics
- Index and table statistics
- Transaction counts and durations
- Replication lag and status

#### Redis Exporter

Redis Exporter collects metrics from Redis instances:

```yaml
# docker-compose.yml (simplified)
monitoring-redis:
  image: oliver006/redis_exporter:v1.55.0
  container_name: monitoring-redis
  ports:
    - "9121:9121"
  environment:
    REDIS_ADDR: redis:6379
  restart: unless-stopped
  networks:
    - alfred-network
```

Key metrics collected:
- Connected clients
- Memory usage
- Command execution rates
- Keyspace statistics
- Eviction and expiration counts

#### Fluent Bit

Fluent Bit collects and forwards logs from all containers:

```yaml
# docker-compose.yml (simplified)
monitoring-logs:
  image: fluent/fluent-bit:2.1
  container_name: monitoring-logs
  volumes:
    - ./monitoring/fluent-bit/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf
    - /var/lib/docker/containers:/var/lib/docker/containers:ro
  restart: unless-stopped
  networks:
    - alfred-network
```

Configuration:
```ini
# fluent-bit.conf
[SERVICE]
    Flush        1
    Log_Level    info
    Parsers_File parsers.conf

[INPUT]
    Name             tail
    Path             /var/lib/docker/containers/*/*.log
    Parser           docker
    Tag              docker.*
    Mem_Buf_Limit    5MB
    Skip_Long_Lines  On

[FILTER]
    Name                kubernetes
    Match               docker.*
    Kube_URL            https://kubernetes.default.svc:443
    Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
    Merge_Log           On
    K8S-Logging.Parser  On
    K8S-Logging.Exclude Off

[OUTPUT]
    Name        loki
    Match       *
    Host        loki
    Port        3100
    Labels      job=fluentbit
    Label_Keys  $container_name,$container_id,$pod_name,$namespace
```

### Processing Layer

The processing layer stores and processes metrics and logs:

#### Prometheus

Prometheus collects, stores, and processes metrics:

```yaml
# docker-compose.yml (simplified)
monitoring-metrics:
  image: prom/prometheus:v2.48.1
  container_name: monitoring-metrics
  ports:
    - "9090:9090"
  volumes:
    - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    - monitoring-metrics-data:/prometheus
  restart: unless-stopped
  networks:
    - alfred-network
```

Configuration:
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['monitoring-node:9100']

  - job_name: 'postgres'
    static_configs:
      - targets: ['monitoring-db:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['monitoring-redis:9121']

  - job_name: 'agent-core'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['agent-core:8011']

  - job_name: 'agent-rag'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['agent-rag:8501']
```

Alert rules:
```yaml
# rules/alerts.yml
groups:
  - name: general
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} has been down for more than 1 minute."

      - alert: HighCPULoad
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[1m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU load (instance {{ $labels.instance }})"
          description: "CPU load is above 80% for more than 5 minutes."
```

#### Alert Manager

Alert Manager handles alert notification routing:

```yaml
# docker-compose.yml (simplified)
alertmanager:
  image: prom/alertmanager:v0.26.0
  container_name: alertmanager
  ports:
    - "9093:9093"
  volumes:
    - ./monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
  restart: unless-stopped
  networks:
    - alfred-network
```

Configuration:
```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXXXXX'

route:
  group_by: ['alertname', 'instance', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-notifications'
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#alfred-monitoring'
        send_resolved: true
        title: '{{ .GroupLabels.alertname }}'
        text: >-
          {{ range .Alerts }}
            *Alert:* {{ .Annotations.summary }}
            *Description:* {{ .Annotations.description }}
            *Severity:* {{ .Labels.severity }}
          {{ end }}

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: '0123456789abcdef0123456789abcdef'
        send_resolved: true
```

#### Loki

Loki collects and stores logs:

```yaml
# docker-compose.yml (simplified)
loki:
  image: grafana/loki:2.9.2
  container_name: loki
  ports:
    - "3100:3100"
  volumes:
    - ./monitoring/loki/loki-config.yaml:/etc/loki/loki-config.yaml
    - monitoring-loki-data:/loki
  command: -config.file=/etc/loki/loki-config.yaml
  restart: unless-stopped
  networks:
    - alfred-network
```

Configuration:
```yaml
# loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
```

### Visualization Layer

#### Grafana

Grafana provides visualization and dashboards:

```yaml
# docker-compose.yml (simplified)
monitoring-dashboard:
  image: grafana/grafana:10.2.3
  container_name: monitoring-dashboard
  ports:
    - "3005:3000"
  volumes:
    - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
    - monitoring-dashboard-data:/var/lib/grafana
  environment:
    GF_SECURITY_ADMIN_PASSWORD: admin
  restart: unless-stopped
  networks:
    - alfred-network
```

Dashboard provisioning:
```yaml
# provisioning/dashboards/dashboards.yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
```

Data source provisioning:
```yaml
# provisioning/datasources/datasources.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://monitoring-metrics:9090
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false
```

## Dashboards

The monitoring infrastructure includes several pre-configured dashboards:

### Platform Overview Dashboard

```json
{
  "dashboard": {
    "id": null,
    "title": "Alfred Platform Overview",
    "tags": ["overview"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "10s",
    "panels": [
      {
        "title": "System Load",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "node_load1"
          },
          {
            "expr": "node_load5"
          },
          {
            "expr": "node_load15"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Buffers_bytes - node_memory_Cached_bytes"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "yaxes": [
          {
            "format": "bytes"
          }
        ]
      },
      {
        "title": "API Request Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        }
      },
      {
        "title": "Response Time",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 8
        }
      },
      {
        "title": "Database Connections",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "pg_stat_activity_count"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 16
        }
      },
      {
        "title": "Redis Memory Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "redis_memory_used_bytes"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 16
        },
        "yaxes": [
          {
            "format": "bytes"
          }
        ]
      }
    ]
  }
}
```

### Agent Service Dashboard

```json
{
  "dashboard": {
    "id": null,
    "title": "Agent Services",
    "tags": ["agents"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "10s",
    "panels": [
      {
        "title": "Request Rate by Agent",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{job=~\"agent-.*\"}[5m])) by (job)"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "title": "Error Rate by Agent",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{job=~\"agent-.*\", status=~\"5..\"}[5m])) by (job) / sum(rate(http_requests_total{job=~\"agent-.*\"}[5m])) by (job)"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "yaxes": [
          {
            "format": "percentunit"
          }
        ]
      },
      {
        "title": "Request Duration",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job=~\"agent-.*\"}[5m])) by (le, job))"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        }
      },
      {
        "title": "Memory Usage by Agent",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(container_memory_usage_bytes{container_name=~\"agent-.*\"}) by (container_name)"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 8
        },
        "yaxes": [
          {
            "format": "bytes"
          }
        ]
      }
    ]
  }
}
```

### Database Performance Dashboard

```json
{
  "dashboard": {
    "id": null,
    "title": "Database Performance",
    "tags": ["database"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "10s",
    "panels": [
      {
        "title": "Active Connections",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "pg_stat_activity_count{state=\"active\"}"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "title": "Transaction Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "rate(pg_stat_database_xact_commit{datname=\"postgres\"}[5m]) + rate(pg_stat_database_xact_rollback{datname=\"postgres\"}[5m])"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "title": "Database Size",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "pg_database_size_bytes"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        },
        "yaxes": [
          {
            "format": "bytes"
          }
        ]
      },
      {
        "title": "Cache Hit Ratio",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "pg_stat_database_blks_hit{datname=\"postgres\"} / (pg_stat_database_blks_hit{datname=\"postgres\"} + pg_stat_database_blks_read{datname=\"postgres\"})"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 8
        },
        "yaxes": [
          {
            "format": "percentunit"
          }
        ]
      }
    ]
  }
}
```

## Alert Rules

The monitoring infrastructure includes the following alert rules:

### System Alerts

| Alert | Description | Severity | Threshold | Duration |
|-------|-------------|----------|-----------|----------|
| InstanceDown | Instance is down | Critical | Instance unreachable | 1m |
| HighCPULoad | High CPU utilization | Warning | >80% | 5m |
| HighMemoryUsage | High memory utilization | Warning | >85% | 5m |
| DiskSpaceLow | Low disk space | Warning | <10% free | 15m |
| DiskSpaceCritical | Critical disk space | Critical | <5% free | 5m |

### Service Alerts

| Alert | Description | Severity | Threshold | Duration |
|-------|-------------|----------|-----------|----------|
| ServiceDown | Service is down | Critical | Service unreachable | 1m |
| HighErrorRate | High error rate | Warning | >1% errors | 5m |
| HighErrorRateCritical | Critical error rate | Critical | >5% errors | 1m |
| SlowResponseTime | Slow response time | Warning | p95 > 500ms | 10m |
| ServiceRestart | Service restarted | Info | Restart detected | Instant |

### Database Alerts

| Alert | Description | Severity | Threshold | Duration |
|-------|-------------|----------|-----------|----------|
| DatabaseConnections | High connection count | Warning | >80% max connections | 10m |
| SlowQueries | Slow queries detected | Warning | Queries > 10s | 5m |
| HighTransactionTime | High transaction time | Warning | p95 > 1s | 10m |
| ReplicationLag | Replication lag | Warning | >30s | 5m |
| TableSize | Large table detected | Info | >10GB | Instant |

## Health Checks

The monitoring infrastructure includes health checks for all components:

### Service Health Checks

```yaml
# Example docker-compose.yml health check configuration
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8011/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

### Health Check Endpoints

Each service exposes a `/health` endpoint that returns:

```json
{
  "status": "healthy",
  "version": "1.2.3",
  "dependencies": [
    {
      "name": "database",
      "status": "healthy"
    },
    {
      "name": "redis",
      "status": "healthy"
    }
  ],
  "checks": [
    {
      "name": "database_connection",
      "status": "pass"
    },
    {
      "name": "redis_connection",
      "status": "pass"
    }
  ]
}
```

## Logging

The monitoring infrastructure includes centralized logging:

### Log Format

All services use a standardized structured logging format:

```json
{
  "timestamp": "2025-05-13T12:34:56.789Z",
  "level": "info",
  "service": "agent-core",
  "message": "Request processed successfully",
  "request_id": "abc123",
  "user_id": "user456",
  "latency_ms": 45.2,
  "status_code": 200
}
```

### Log Levels

| Level | Usage |
|-------|-------|
| ERROR | Service failures that require immediate attention |
| WARN | Potential issues that don't affect service operation |
| INFO | Normal operational events |
| DEBUG | Detailed information for troubleshooting |
| TRACE | Most detailed level, rarely used in production |

### Log Queries

Grafana provides Loki-based log querying:

```
{container_name="agent-core"} |= "error"
```

Log correlation using Grafana's trace visualization:

```
{trace_id="abc123"}
```

## Capacity Planning

The monitoring infrastructure is designed to handle the following scale:

| Component | Capacity |
|-----------|----------|
| Prometheus | 100,000 metrics with 15s scrape interval |
| Loki | 10GB logs per day with 14-day retention |
| Grafana | 20 concurrent users |

Storage requirements:

| Component | Storage | Retention |
|-----------|---------|-----------|
| Prometheus | 50GB | 15 days |
| Loki | 150GB | 14 days |
| Grafana | 1GB | N/A |

## Deployment

### Prerequisites

- Docker and Docker Compose
- At least 4GB of memory for the monitoring stack
- At least 200GB of disk space for metrics and logs

### Installation Steps

1. Create the necessary directories:
   ```bash
   mkdir -p monitoring/{prometheus,alertmanager,grafana/{dashboards,provisioning/{datasources,dashboards}},loki}
   ```

2. Create configuration files:
   ```bash
   # Create Prometheus configuration
   cat > monitoring/prometheus/prometheus.yml << EOF
   global:
     scrape_interval: 15s
     evaluation_interval: 15s

   rule_files:
     - /etc/prometheus/rules/*.yml

   alerting:
     alertmanagers:
       - static_configs:
           - targets:
               - alertmanager:9093

   scrape_configs:
     # ... scrape configs as shown above ...
   EOF

   # Create Alert Manager configuration
   cat > monitoring/alertmanager/alertmanager.yml << EOF
   global:
     resolve_timeout: 5m
     slack_api_url: 'https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXXXXXXX'

   # ... alert manager config as shown above ...
   EOF

   # Create Loki configuration
   cat > monitoring/loki/loki-config.yaml << EOF
   auth_enabled: false

   # ... loki config as shown above ...
   EOF

   # Create Grafana dashboard provisioning
   cat > monitoring/grafana/provisioning/dashboards/dashboards.yaml << EOF
   apiVersion: 1

   providers:
     - name: 'default'
       orgId: 1
       folder: ''
       type: file
       disableDeletion: false
       updateIntervalSeconds: 30
       allowUiUpdates: true
       options:
         path: /var/lib/grafana/dashboards
         foldersFromFilesStructure: true
   EOF

   # Create Grafana datasource provisioning
   cat > monitoring/grafana/provisioning/datasources/datasources.yaml << EOF
   apiVersion: 1

   datasources:
     - name: Prometheus
       type: prometheus
       access: proxy
       url: http://monitoring-metrics:9090
       isDefault: true
       editable: false

     - name: Loki
       type: loki
       access: proxy
       url: http://loki:3100
       editable: false
   EOF
   ```

3. Deploy the monitoring stack:
   ```bash
   docker-compose -f docker-compose.monitoring.yml up -d
   ```

4. Verify deployment:
   ```bash
   docker-compose -f docker-compose.monitoring.yml ps
   ```

5. Access Grafana:
   - URL: http://localhost:3005
   - Username: admin
   - Password: admin (change on first login)

## Maintenance

### Backup and Restore

1. Backup Prometheus data:
   ```bash
   docker run --rm -v monitoring-metrics-data:/data -v $(pwd)/backups:/backups \
     alpine tar -czf /backups/prometheus-backup-$(date +%Y%m%d).tar.gz /data
   ```

2. Backup Grafana data:
   ```bash
   docker run --rm -v monitoring-dashboard-data:/data -v $(pwd)/backups:/backups \
     alpine tar -czf /backups/grafana-backup-$(date +%Y%m%d).tar.gz /data
   ```

3. Restore Prometheus data:
   ```bash
   docker run --rm -v monitoring-metrics-data:/data -v $(pwd)/backups:/backups \
     alpine sh -c "rm -rf /data/* && tar -xzf /backups/prometheus-backup-YYYYMMDD.tar.gz -C /"
   ```

4. Restore Grafana data:
   ```bash
   docker run --rm -v monitoring-dashboard-data:/data -v $(pwd)/backups:/backups \
     alpine sh -c "rm -rf /data/* && tar -xzf /backups/grafana-backup-YYYYMMDD.tar.gz -C /"
   ```

### Upgrading Components

To upgrade monitoring components:

1. Update the image version in the Docker Compose file
2. Pull the updated image:
   ```bash
   docker-compose -f docker-compose.monitoring.yml pull
   ```
3. Restart the service:
   ```bash
   docker-compose -f docker-compose.monitoring.yml up -d
   ```

## Troubleshooting

### Common Issues

1. **Prometheus is not collecting metrics**:
   - Check if the target is registered in Prometheus:
     ```bash
     curl http://localhost:9090/api/v1/targets
     ```
   - Verify the target is exposing metrics:
     ```bash
     curl http://target-host:port/metrics
     ```
   - Check Prometheus logs:
     ```bash
     docker logs monitoring-metrics
     ```

2. **Grafana cannot connect to Prometheus**:
   - Verify Prometheus is running:
     ```bash
     docker ps | grep monitoring-metrics
     ```
   - Check the Grafana data source configuration
   - Ensure the networks are properly connected

3. **Alerts are not firing**:
   - Check if Alert Manager is running:
     ```bash
     docker ps | grep alertmanager
     ```
   - Verify alert rules are loaded:
     ```bash
     curl http://localhost:9090/api/v1/rules
     ```
   - Check Alert Manager configuration:
     ```bash
     docker exec alertmanager amtool config show
     ```

4. **Loki is not receiving logs**:
   - Check if Fluent Bit is running:
     ```bash
     docker ps | grep monitoring-logs
     ```
   - Verify Fluent Bit configuration
   - Check Loki logs:
     ```bash
     docker logs loki
     ```

### Debugging Commands

1. Check Prometheus targets:
   ```bash
   curl http://localhost:9090/api/v1/targets | jq .
   ```

2. Query Prometheus metrics:
   ```bash
   curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=up'
   ```

3. Check Alert Manager alerts:
   ```bash
   curl http://localhost:9093/api/v1/alerts
   ```

4. Query Loki logs:
   ```bash
   curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
     --data-urlencode 'query={container_name="agent-core"}' \
     --data-urlencode 'start=1619712000000000000' \
     --data-urlencode 'end=1619798400000000000' \
     --data-urlencode 'limit=10'
   ```

## Related Documentation

- [Docker Compose Configuration](../containerization/docker-compose-configuration.md)
- [Kubernetes Deployment](../containerization/kubernetes-deployment.md)
- [Networking Architecture](../networking/networking-architecture.md)
- [Service Mesh Configuration](../networking/service-mesh-configuration.md)

## References

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/manual)
