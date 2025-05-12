# Social Intelligence Platform Integration

This document describes the integration of the Social Intelligence service with the Alfred Agent Platform v2 shared services, including RAG Gateway and Supabase persistence.

## Integration Approach

The integration follows a hybrid approach to maintain backward compatibility while introducing platform services:

1. **Hybrid Mode**: By default, the service runs in hybrid mode, which tries platform services first, then falls back to original implementations if needed.
2. **Migration Modes**: Three modes are supported:
   - `legacy`: Uses only original implementations
   - `hybrid`: Tries platform services first, falls back to original implementations
   - `platform`: Uses only platform services (will fail if not available)
3. **File Fallback**: Even when using platform services, file-based storage is maintained as a fallback mechanism during the transition.

## New Components

The integration adds the following components:

1. **Platform Clients**: New client modules in `app/clients/`
   - `supabase_client.py`: Handles Supabase persistence with file fallback
   - `rag_client.py`: Integrates with RAG Gateway while maintaining direct Qdrant access
   - `auth_middleware.py`: Provides authentication with API keys and JWT

2. **Enhanced Implementations**: Improved implementations that use platform services
   - `niche_scout_enhanced.py`: Enhances NicheScout with RAG capabilities

3. **Configuration**: Environment variables to control the integration
   - `.env.migration`: Configuration file for controlling migration behavior

## Usage

To use the integrated service:

1. **Configure Migration Mode**:
   ```bash
   # Set to hybrid for backward compatibility
   export MIGRATION_MODE=hybrid
   
   # Or use only platform services
   export MIGRATION_MODE=platform
   
   # Or use only original implementations
   export MIGRATION_MODE=legacy
   ```

2. **Set Up Required Tables**:
   ```bash
   # Run setup script to create necessary Supabase tables
   ./scripts/setup_social_tables.sh
   ```

3. **Start the Service**:
   ```bash
   # Start with configuration
   docker-compose -f docker-compose.dev.yml up -d social-intel
   ```

## API Keys

The integrated service supports API key authentication:

- Default API key: `social-intel-key` (can be changed via `API_KEY` environment variable)
- Platform API keys format: `agent:key,agent:key` (can be configured via `PLATFORM_API_KEYS` environment variable)

API keys can be provided in:
1. `X-API-Key` header
2. `Authorization: Bearer <api-key>` header
3. `?api_key=<api-key>` query parameter

## Testing the Integration

To test the integration:

1. **Workflow History**:
   ```bash
   curl -H "X-API-Key: social-intel-key" http://localhost:9000/workflow-history
   ```

2. **Run Niche Scout Workflow**:
   ```bash
   curl -X POST -H "X-API-Key: social-intel-key" \
     "http://localhost:9000/niche-scout?query=financial+education"
   ```

3. **Retrieve Results**:
   ```bash
   # Get the result ID from the response and use it here
   curl -H "X-API-Key: social-intel-key" \
     "http://localhost:9000/workflow-result/{result_id}?type=niche-scout"
   ```

## Verifying Platform Service Usage

To verify that platform services are being used:

1. Check logs for messages like:
   - "Retrieved workflow result from Supabase"
   - "Retrieved context from RAG Gateway"

2. Check Supabase for stored results:
   - Look for entries in the `social_out` table

3. Check RAG Gateway for indexed documents:
   - Query the `social-intel-knowledge` collection

## Troubleshooting

Common issues and solutions:

1. **"Authentication failed"**: Ensure API key is correctly set and provided in requests
2. **"Table not found"**: Run `./scripts/setup_social_tables.sh` to create needed tables
3. **"RAG Gateway not reachable"**: Ensure RAG Gateway is running and accessible
4. **"Error storing result in Supabase"**: Check Supabase connection and permissions

## Future Work

1. Complete transition to platform services
2. Remove file fallback once system is stable
3. Add automated tests for platform integration
4. Improve error handling and recovery mechanisms