# Port Mismatch Matrix for Unhealthy Services

## Database Metrics Services (All have same issue)
| Service | Container Ports | Health Check | Issue |
|---------|----------------|--------------|-------|
| db-admin-metrics | Listening on 9103 | Checking http://localhost:9091/metrics | **MISMATCH: Should check 9103/health** |
| db-api-metrics | Listening on 9103 | Checking http://localhost:9091/metrics | **MISMATCH: Should check 9103/health** |
| db-auth-metrics | Listening on 9103 | Checking http://localhost:9091/metrics | **MISMATCH: Should check 9103/health** |
| db-realtime-metrics | Listening on 9103 | Checking http://localhost:9091/metrics | **MISMATCH: Should check 9103/health** |
| db-storage-metrics | Listening on 9103 | Checking http://localhost:9091/metrics | **MISMATCH: Should check 9103/health** |

## Agent Services
| Service | Container Ports | Health Check | Issue |
|---------|----------------|--------------|-------|
| agent-atlas | 8000:8000 | Checking http://localhost:8000/health | Logs are empty - service not starting |
| agent-social | 9000:9000 | Checking http://localhost:9000/health | Logs are empty - service not starting |

## Model Services
| Service | Container Ports | Health Check | Issue |
|---------|----------------|--------------|-------|
| model-router | 8080:8080 | Checking http://localhost:8080/health | Logs are empty - service not starting |
| model-registry | 8079:8079 | Checking http://localhost:8079/health | Logs are empty - service not starting |

## Database Services
| Service | Container Ports | Health Check | Issue |
|---------|----------------|--------------|-------|
| db-admin | 3000:3000 | Checking http://localhost:3000/health | Service specific issue |
| db-api | 3000:3000 | Checking http://localhost:3000/health | Service specific issue |
| db-realtime | 4000:4000 | Checking http://localhost:4000/health | Service specific issue |
| db-storage | 5000:5000, 5001:5001 | Checking http://localhost:5000/health/ready | Service specific issue |

## UI Services
| Service | Container Ports | Health Check | Issue |
|---------|----------------|--------------|-------|
| ui-admin | 3007:3007 | Checking http://localhost:3007/ | Service specific issue |

## Other Services
| Service | Container Ports | Health Check | Issue |
|---------|----------------|--------------|-------|
| hubspot-mock | 8088:8000 | Checking http://localhost:8000/health | Container listening on 8000 |
| mail-server | 1025:1025, 8025:8025 | Checking http://localhost:8025/api/v2/messages?limit=1 | Service specific |
| llm-service | 11434:11434 | Checking http://localhost:11434/api/tags | Ollama service - slow start |
| vector-db | 19530:19530 | Checking http://localhost:19530/v1/vector/collections | Milvus - slow start |

## Monitoring Services
| Service | Container Ports | Health Check | Issue |
|---------|----------------|--------------|-------|
| monitoring-db | 9187:9187 | Checking http://localhost:9187/metrics | Postgres exporter |
| monitoring-redis | 9121:9121 | Checking http://localhost:9121/metrics | Redis exporter |
| monitoring-node | 9100:9100 | Checking http://localhost:9100/metrics | Node exporter |
| redis-exporter | 9121:9121 | Checking http://localhost:9121/metrics | Redis exporter |

## Summary of Issues:
1. **All db-*-metrics services**: Health check using wrong port (9091 instead of 9103) and wrong endpoint (/metrics instead of /health)
2. **Agent services (atlas, social)**: Not starting at all - need to check Dockerfile/build issues
3. **Model services**: Not starting at all - need to check Dockerfile/build issues
4. **Database services**: Various startup issues
5. **LLM/Vector services**: Slow start - need longer start_period
