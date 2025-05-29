# Phase 2 Database Migration Plan

This document outlines the database migration strategy for Phase 2 (Advanced Analytics) of the Social Intelligence service.

## Migration Strategy

We'll use a forward-only migration approach with Flyway to ensure consistent schema changes across all environments. Each migration will be versioned and applied sequentially.

## Schema Changes

### New Tables

The following new tables will be created:

1. **analytics_events**: Stores granular event data for analytics
2. **trend_cache**: Caches trend calculation results
3. **cross_platform_metrics**: Stores normalized metrics across platforms
4. **content_recommendations**: Stores personalized content recommendations
5. **ml_features**: Stores feature vectors for machine learning
6. **insight_registry**: Tracks generated insights and their metadata

### Modified Tables

The following existing tables will be modified:

1. **features**:
   - Add `trend_vector` column (JSONB) for time-series data
   - Add `last_analyzed_at` timestamp
   - Add `analytics_version` integer for tracking analysis version

2. **hot_niches_today**:
   - Add `trend_direction` column
   - Add `trend_confidence` column
   - Add `days_trending` column

## Migration Files

The following SQL migration files will be created:

1. `V2.0.0__analytics_schema.sql`
2. `V2.0.1__trend_analysis_tables.sql`
3. `V2.0.2__cross_platform_tables.sql`
4. `V2.0.3__recommendations_tables.sql`
5. `V2.0.4__modify_existing_tables.sql`
6. `V2.0.5__create_analytics_indices.sql`
7. `V2.0.6__create_analytics_views.sql`

## Sample Migration Script

```sql
-- V2.0.0__analytics_schema.sql
CREATE SCHEMA IF NOT EXISTS analytics;

-- Event tracking table
CREATE TABLE analytics.analytics_events (
  event_id BIGSERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  event_source TEXT NOT NULL,
  event_timestamp TIMESTAMPTZ NOT NULL,
  event_data JSONB NOT NULL,
  user_id TEXT,
  niche_id BIGINT REFERENCES features(niche_id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index on common query patterns
CREATE INDEX idx_analytics_events_timestamp ON analytics.analytics_events(event_timestamp);
CREATE INDEX idx_analytics_events_type_source ON analytics.analytics_events(event_type, event_source);
CREATE INDEX idx_analytics_events_niche_id ON analytics.analytics_events(niche_id);
CREATE INDEX idx_analytics_events_user_id ON analytics.analytics_events(user_id);
```

## Backfill Strategy

For historical data, we'll implement a backfill process:

1. **Initial Backfill**:
   - Run during non-peak hours
   - Process in batches of 10,000 records
   - Prioritize most recent 90 days

2. **Incremental Backfill**:
   - Schedule daily jobs for older data
   - Complete full historical backfill within 7 days

## Rollback Strategy

In case of issues, we've prepared rollback scripts for each migration:

1. `U2.0.0__rollback_analytics_schema.sql`
2. `U2.0.1__rollback_trend_analysis_tables.sql`
3. etc.

Rollback process:
1. Disable application access to affected tables
2. Execute appropriate rollback script
3. Verify data integrity
4. Re-enable application access

## Data Migration Considerations

### Data Volume

- Estimated rows in new tables: ~10M in first month
- Estimated growth rate: 500K rows/day
- Total storage requirements: ~20GB initial, ~100GB after 6 months

### Performance Impact

- Migrations will be executed during maintenance windows
- Index creation may temporarily impact write performance
- Read performance will be maintained through staged approach

### Data Integrity

- Foreign key constraints enforced for referential integrity
- Check constraints for data validation
- Triggers for maintaining materialized views

## Monitoring

During migration:
- Track execution time of each migration step
- Monitor database load and connection count
- Alert on migration steps exceeding 5 minutes

Post-migration:
- Monitor query performance on new tables
- Track index usage statistics
- Verify data consistency between old and new structures

## Testing Strategy

1. **Development**: Test migrations on development snapshot
2. **Staging**: Full rehearsal with production-like data volume
3. **Production**: Execute during maintenance window with monitoring

## Deployment Steps

1. **Preparation**:
   - Verify database backups
   - Increase log retention temporarily
   - Notify relevant teams

2. **Execution**:
   - Apply migrations sequentially
   - Validate after each step
   - Run verification queries

3. **Post-Deployment**:
   - Run performance tests
   - Update documentation
   - Monitor application behavior

## Schedule

- **Development**: Week of 2025-05-15
- **Staging**: Week of 2025-05-22
- **Production**: Weekend of 2025-05-31 (maintenance window)

## Responsible Team

- Database Administrator: [Name]
- Application Developer: [Name]
- DevOps Engineer: [Name]
