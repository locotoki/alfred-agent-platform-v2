# Prometheus Configuration Cleanup

This document describes the improvements made to the Prometheus configuration to resolve targeting and naming issues.

## Previous Issues

The Prometheus configuration had several issues:

1. **Obsolete Container Names**: References to old container names (alfred-bot, financial-tax, legal-compliance, social-intel) that had been renamed or replaced
2. **Duplicate Entries**: Some services appeared multiple times with different job names
3. **Inconsistent Naming**: Target names didn't match the actual container names
4. **Unorganized Structure**: Jobs were not grouped logically by service type

## Improvements Made

The Prometheus configuration was completely rebuilt to:

1. **Remove Obsolete Names**: All references to old/obsolete container names were removed
2. **Standardize Job Names**: Jobs were renamed to match the actual container names
3. **Group by Service Type**: Jobs were organized by service category:
   - Core Agent Services
   - LLM Model Services
   - Infrastructure Services
   - Database Services
   - UI Services
4. **Add Documentation**: Added detailed comments to explain the job structure

## Container Name Mapping

The following name changes were made to align with current container naming:

| Old Name | New Name |
|----------|----------|
| alfred-bot | agent-core |
| financial-tax | agent-financial |
| legal-compliance | agent-legal |
| social-intel | agent-social |

## Current Service Structure

The current service structure in Prometheus now matches the container structure:

### Core Agent Services
- agent-core
- agent-social
- agent-rag

### LLM Model Services
- model-registry
- model-router

### Infrastructure Services
- vector-db
- redis
- pubsub-metrics

### Database Services
- db-postgres
- db-auth-metrics
- db-api-metrics
- db-admin-metrics
- db-realtime-metrics
- db-storage-metrics

### UI Services
- ui-admin

## Duplicate Entry Issue

You may still see some duplicate entries in the Prometheus targets view. This occurs because:

1. Prometheus keeps both old and new target configurations during service discovery
2. Old targets remain in the system until they time out (usually after several minutes)
3. The service discovery mechanism runs independently of configuration changes

This issue will resolve itself over time as the old targets time out, or after a full restart of Prometheus with clean persistent storage.

## Port Allocation

We've established a consistent port allocation scheme for metrics:

| Service Category | Port Range |
|------------------|------------|
| Core Services | 9091-9099 |
| Infrastructure Services | 9101-9103 |
| Database Services | 9120-9124 |
| Monitoring Services | 9100, 9187 |

## Next Steps

1. Wait for duplicate entries to disappear (or restart Prometheus again)
2. Create Grafana dashboards based on the new job/target structure
3. Set up alerting rules based on the new job/target structure
4. Update documentation with the new monitoring structure
