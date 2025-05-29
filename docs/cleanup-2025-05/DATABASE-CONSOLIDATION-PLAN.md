# Database Services Consolidation Plan

## Services to Keep
1. **db-postgres** - Core PostgreSQL database (ESSENTIAL)
2. **db-exporter** - PostgreSQL metrics (keep one)

## Services to Evaluate
3. **db-auth** - Check if authentication is used
4. **db-api** - Check if REST API is used

## Services to Remove
5. **db-storage** - Broken (wrong image)
6. **db-admin** - Missing dependencies  
7. **db-realtime** - Unless real-time features are used
8. **monitoring-db** - Duplicate of db-exporter
9. All *-metrics services - Excessive monitoring

## Next Steps
1. Test if removing db-api breaks any agents
2. Test if removing db-auth breaks authentication
3. If both can be removed, we go from 9+ containers to 2
