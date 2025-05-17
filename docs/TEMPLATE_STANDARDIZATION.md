# Health Check Template Standardization

## Overview

This document describes the standardization of health check implementations across all Alfred Platform services. By adopting a consistent template approach, we ensure that all services implement health checks in a consistent manner, making maintenance, monitoring, and reliability improvements more straightforward.

## Canonical Templates

The following canonical templates have been created:

1. `templates/healthcheck.Dockerfile.tmpl` - Standardized Dockerfile configuration for health checks
2. `templates/entrypoint.sh.tmpl` - Standardized entrypoint script for service initialization with health check integration

These templates provide a consistent pattern for:
- Multi-stage Docker builds to include the health check binary
- Standard health check command with consistent parameters
- Service initialization with proper cleanup handling
- Prometheus metrics export on a standardized port (9091)

## Standardization Process

Each service in the platform should be updated to follow these templates. The standardization process includes:

1. Updating the service's Dockerfile to follow the multi-stage build pattern
2. Using a standardized entrypoint script that starts the health check binary
3. Exposing health endpoints with consistent paths and response formats
4. Configuring the health check binary with standardized parameters

## Example Conversion: Model Registry Service

The Model Registry service has been converted to use the standardized templates as a reference implementation.

### Before Standardization

The service previously used:
- A custom Dockerfile without multi-stage build
- No standardized health check binary integration
- Custom health endpoint implementations
- No standardized metrics export

### After Standardization

The service now uses:
- A standardized Dockerfile based on the template
- The standard health check binary 
- A standardized entrypoint script that starts both the service and health check
- Consistent health check parameters and metrics export

## Implementation Requirements

All services must conform to the following requirements:

1. Use multi-stage builds to include the health check binary
2. Expose health endpoints at consistent paths (`/health`)
3. Return standardized health status responses
4. Export Prometheus metrics on port 9091
5. Use the standardized entrypoint script pattern

## Validation

A CI validation step has been added to ensure all services follow the standardized pattern. This validation checks:

1. Dockerfile structure conforms to the template
2. Health check commands use standardized parameters
3. Entrypoint scripts include health check initialization
4. Health endpoints return the expected format

## Migration Plan

All existing services will be migrated to the new template according to the following phases:

1. Infrastructure services (completed)
2. Core platform services (in progress)
3. Agent services
4. UI and frontend services

## Benefits

The standardization of health check templates provides several benefits:

1. Consistent monitoring experience across all services
2. Simplified maintenance and updates
3. Improved reliability through standardized health reporting
4. Easier onboarding for new services and developers
5. Consolidated metrics collection for platform-wide health dashboards