# Port Conflict Resolution

## Issue Identified

The Mission Control UI was showing Swagger documentation when accessed at `http://localhost:3000` instead of the expected dashboard. 

After investigation, the cause was identified:

1. The Mission Control UI was configured to run on port 3000
2. The Supabase REST API service was also using port 3000
3. This conflict caused the Swagger API documentation from Supabase to be displayed instead of the Mission Control UI

## Solution Applied

The Mission Control UI has been reconfigured to use port 3005 instead of port 3000 to avoid the conflict:

1. Updated `package.json` to use port 3005 for dev and start scripts
2. Updated `next.config.js` to set the server port to 3005
3. Updated `.env.local` with the new server URL
4. Updated all references to the server URL in code
5. Updated the restart script to use port 3005

## How to Access the App

The Mission Control UI is now accessible at:

```
http://localhost:3005
```

## Technical Details

The port conflict occurred because the docker-compose.yml file contains the following service definition:

```yaml
supabase-rest:
  image: postgrest/postgrest:v11.2.0
  container_name: supabase-rest
  depends_on:
    supabase-db:
      condition: service_healthy
  ports:
    - "3000:3000"  # This maps the host port 3000 to the container port 3000
  environment:
    PGRST_DB_URI: postgres://authenticator:${POSTGRES_PASSWORD}@supabase-db:5432/postgres
    PGRST_DB_SCHEMAS: public,storage,graphql_public
    PGRST_DB_ANON_ROLE: anon
    PGRST_JWT_SECRET: ${JWT_SECRET}
```

This service runs the Supabase REST API (PostgREST) on port 3000, which conflicts with the Mission Control UI.

### Alternative Solutions

Other potential solutions would be:

1. Change the Supabase REST API port in docker-compose.yml
2. Use a reverse proxy to route requests appropriately
3. Configure the Mission Control UI to run on a subdirectory

However, changing the port for the Mission Control UI was the simplest and least disruptive solution.