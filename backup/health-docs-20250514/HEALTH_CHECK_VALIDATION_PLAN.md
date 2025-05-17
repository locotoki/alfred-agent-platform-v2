# Health Check Validation Plan

This document outlines the detailed validation plan for testing the health check implementation across all services in the Alfred Agent Platform v2.

## Validation Objectives

1. Verify all health endpoints return the correct response format
2. Verify all metrics endpoints export Prometheus-compatible metrics
3. Test dependency tracking across services
4. Validate healthcheck binary functionality
5. Confirm Prometheus scraping works correctly
6. Test resilience during service degradation

## Test Matrix

| Test Case | Description | Success Criteria | Status |
|-----------|-------------|------------------|--------|
| TC-01 | Health endpoint basic response | Status "ok" in JSON response | Partially Tested |
| TC-02 | Healthz endpoint response | Simple JSON status response | Not Tested |
| TC-03 | Metrics endpoint format | Valid Prometheus text format | Partially Tested |
| TC-04 | Docker healthcheck | Container reports as healthy | Partially Tested |
| TC-05 | Prometheus scraping | Metrics appear in Prometheus UI | Not Tested |
| TC-06 | Dependency tracking | Dependencies reported in health response | Not Tested |
| TC-07 | Degradation resilience | Status changes to "degraded" when appropriate | Not Tested |
| TC-08 | Failure detection | Status changes to "error" when appropriate | Not Tested |

## Step-by-Step Validation Procedure

### Phase 1: Individual Service Testing

For each service, complete the following tests:

1. **Basic Health Endpoint Test**
   - Command: `curl -s http://localhost:<PORT>/health`
   - Expected: JSON response with "status": "ok"

2. **Simple Health Probe Test**
   - Command: `curl -s http://localhost:<PORT>/healthz`
   - Expected: Simple JSON response with "status": "ok"

3. **Metrics Endpoint Test**
   - Command: `curl -s http://localhost:<PORT>/metrics`
   - Expected: Prometheus text format response with valid metrics

4. **Docker Healthcheck Test**
   - Command: `docker inspect --format='{{.State.Health.Status}}' <CONTAINER_NAME>`
   - Expected: "healthy"

### Phase 2: Integration Testing

5. **Prometheus Scraping Test**
   - Navigate to Prometheus UI (http://localhost:9090)
   - Query: `service_health{instance="alfred-platform"}`
   - Expected: All services return value 1

6. **Dependency Tracking Test**
   - Stop dependent service (e.g., model-registry)
   - Check health endpoint of depending service (e.g., model-router)
   - Expected: Dependency shows as "error" in services object

7. **Degradation Resilience Test**
   - Simulate degraded service (e.g., slow database)
   - Check health endpoint
   - Expected: Status changes to "degraded"

8. **Failure Detection Test**
   - Simulate service failure (e.g., kill dependent service)
   - Check health endpoint
   - Expected: Status changes to "error"

## Validation Schedule

| Service | Phase 1 | Phase 2 |
|---------|---------|---------|
| agent-core | COMPLETE | NOT STARTED |
| model-registry | COMPLETE | NOT STARTED |
| model-router | COMPLETE | NOT STARTED |
| agent-financial | NOT STARTED | NOT STARTED |
| agent-legal | NOT STARTED | NOT STARTED |
| agent-rag | NOT STARTED | NOT STARTED |
| ui-chat | NOT STARTED | NOT STARTED |
| ui-admin | NOT STARTED | NOT STARTED |

## Validation Tools

### 1. Automated Validation Script

The `verify-health-endpoints.sh` script performs basic validation:
- Checks health endpoints for correct response format
- Checks metrics endpoints for Prometheus compatibility
- Provides summary of validation results

### 2. Manual Test Cases

For more complex scenarios:
- Dependency failure testing
- Performance degradation testing
- Recovery testing

### 3. Prometheus UI Validation

For metrics collection validation:
- Query metrics in Prometheus UI
- Verify target scraping
- Check data points over time

## Troubleshooting Guide

### Common Issues and Resolutions

1. **Health Endpoint Returns 404**
   - Verify service is running
   - Check port mapping in docker-compose.yml
   - Confirm endpoint implementation in code

2. **Metrics Not Appearing in Prometheus**
   - Verify metrics endpoint is accessible
   - Check Prometheus configuration
   - Confirm port mapping and networking

3. **Docker Healthcheck Failing**
   - Check logs with `docker logs <CONTAINER_NAME>`
   - Verify healthcheck command in docker-compose.yml
   - Check network connectivity within container

## Validation Progress Tracking

| Date | Services Tested | Test Cases | Results | Follow-up Actions |
|------|-----------------|------------|---------|-------------------|
| 2025-05-14 | agent-core, model-registry, model-router | TC-01, TC-03, TC-04 | PASSED | Complete remaining test cases |
| | | | | |
| | | | | |

## Success Criteria

The health check implementation will be considered successfully validated when:

1. All services pass basic health endpoint tests (TC-01, TC-02, TC-03)
2. All Docker healthchecks report containers as healthy (TC-04)
3. Prometheus successfully scrapes metrics from all services (TC-05)
4. Dependency tracking correctly reports dependencies (TC-06)
5. Service degradation is properly reported (TC-07, TC-08)

## Final Validation Report

After completing all tests, a final validation report will be generated documenting:
- Test results for each service
- Any issues identified and their resolutions
- Recommendations for ongoing monitoring
- Performance metrics for health check response times