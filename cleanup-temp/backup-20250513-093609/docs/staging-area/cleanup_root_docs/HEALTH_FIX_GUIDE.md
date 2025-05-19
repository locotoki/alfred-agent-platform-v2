# Health Check Fix Guide

This document explains how to fix the health check issues in the Alfred Agent Platform v2.

## Overview of Issues

The following containers were reporting as unhealthy:

1. **agent-atlas (Infrastructure Architect)**
   - Issue: The health check was looking for a specific process (`tail -f /dev/null`) that wasn't running
   - Fix: Start the required process in the container

2. **agent-core (Core Agent Framework)**
   - Issue: Missing `/metrics` endpoint for Prometheus scraping
   - Fix: Added Prometheus metrics endpoint and enhanced health checks

3. **agent-rag (RAG Gateway)**
   - Issue: Missing `/metrics` endpoint for Prometheus scraping
   - Fix: Added Prometheus metrics endpoint and enhanced health checks

4. **ui-admin (Admin UI)**
   - Issue: Health check configured for port 3000, but service running on port 3007
   - Fix: Updated health check to use the correct port

5. **monitoring-db (Postgres Exporter)**
   - Issue: Authentication failing to PostgreSQL database with incorrect password
   - Fix: Updated connection string with correct database credentials

6. **vector-db (Qdrant)**
   - Issue: Health check using `curl` which wasn't installed in the container
   - Fix: Install curl or create a custom health check script

## Fix Scripts

The following scripts have been created to fix each issue:

1. **fix-atlas-container.sh**
   - Ensures the Atlas container is running the required process for health checks

2. **fix-agent-core.sh**
   - Adds Prometheus metrics and enhanced health endpoints to agent-core

3. **fix-agent-rag.sh**
   - Adds Prometheus metrics and enhanced health endpoints to agent-rag

4. **fix-ui-admin.sh**
   - Corrects the health check configuration for ui-admin

5. **fix-monitoring-db.sh**
   - Updates the database connection string with the correct credentials

6. **fix-vector-db.sh**
   - Installs curl or creates a custom health check script for vector-db

7. **fix-all-health-checks.sh**
   - Master script that runs all individual fix scripts for unhealthy containers

## Usage

To fix all unhealthy containers, run:

```bash
./fix-all-health-checks.sh
```

To fix individual containers, run their respective fix scripts:

```bash
./fix-atlas-container.sh
./fix-agent-core.sh
./fix-agent-rag.sh
./fix-ui-admin.sh
./fix-monitoring-db.sh
./fix-vector-db.sh
```

## Verifying Fixes

After running the fix scripts, verify that all containers are healthy:

```bash
docker ps --filter health=unhealthy
```

If no containers are listed, all health checks are passing.

## Long-term Solutions

For a more permanent solution, consider:

1. Updating the Docker Compose files with correct health check configurations
2. Adding the necessary health endpoints to all services
3. Ensuring all containers have the required tools for health checks
4. Documenting standard health check patterns for future services

## Health Check Standards

All services should follow these health check standards:

1. **Basic Health Check**
   - Endpoint: `/healthz`
   - Purpose: Simple liveness check
   - Response: `{"status":"ok"}` with HTTP 200

2. **Detailed Health Check**
   - Endpoint: `/health`
   - Purpose: Detailed service health with dependencies
   - Response Format:
     ```json
     {
       "status": "ok|degraded",
       "version": "1.0.0",
       "services": {
         "dependency1": "ok|degraded|unknown",
         "dependency2": "ok|degraded|unknown"
       }
     }
     ```

3. **Metrics Endpoint**
   - Endpoint: `/metrics`
   - Purpose: Prometheus metrics
   - Format: Prometheus exposition format
