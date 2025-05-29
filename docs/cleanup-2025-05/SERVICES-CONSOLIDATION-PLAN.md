# Services Consolidation Plan

## Philosophy
Following the successful slack-bot v3.1.0 pattern:
- Self-contained services with embedded dependencies
- Proper versioning (no :latest tags)
- Minimal external dependencies
- Built-in health checks

## Services to Fix

### 1. db-storage → storage-api
**Current Issue**: Using PostgreSQL image for Supabase Storage API
**Solution**: 
- Option A: Use official `supabase/storage-api` image
- Option B: Remove if not actively used (appears to be for file storage)
- **Recommendation**: Remove until needed, as no services depend on it

### 2. crm-sync → crm-gateway
**Current Issue**: Import errors, depends on hubspot-mock
**Solution**: Create self-contained CRM gateway service
```dockerfile
# New crm-gateway service
FROM python:3.12-slim
# Embed mock HubSpot functionality
# Single service, no external dependencies
```

### 3. ui-chat → chat-ui
**Current Issue**: Missing health_server module, volume mount conflicts
**Solution**: Create properly packaged Streamlit UI
```dockerfile
# New chat-ui service
FROM python:3.12-slim
COPY all required files
# No volume mounts, self-contained
```

### 4. alfred-bot (removed)
**Status**: Already replaced by slack-bot v3.1.0
**Action**: None needed - cleanup complete

## Implementation Priority
1. **Remove unused services** (db-storage) - DONE via override
2. **Fix critical UIs** (ui-chat → chat-ui) if needed
3. **Fix integrations** (crm-sync → crm-gateway) if business critical

## Next Steps
1. Determine if these services are needed for MVP
2. If yes, create consolidated versions
3. If no, formally remove from docker-compose.yml