# Supabase Authentication Status

## Current Configuration

For development purposes, authentication has been disabled in the PostgREST configuration. This means:

1. Row Level Security (RLS) is disabled on all tables
2. The database is accessible without authentication
3. All services can directly access the API without tokens

## How to Use

Services can access the Supabase REST API directly without authentication headers:

```bash
# Read from a table
curl http://supabase-rest:3000/architect_in

# Write to a table
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"data":{"message":"test"}}' \
  http://supabase-rest:3000/architect_in
```

## Future Improvements

For production deployment, proper authentication should be configured:

1. Enable Row Level Security
2. Configure JWT authentication with proper signing keys
3. Implement proper schema migrations
4. Set up secure API key handling

## Troubleshooting

If services cannot access Supabase, check:

1. Network connectivity between containers
2. PostgREST configuration in `/etc/postgrest.conf`
3. Database schema integrity
4. Table permissions

To reset the current configuration, run:

```bash
./disable-auth.sh
```
