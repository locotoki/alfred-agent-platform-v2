# Supabase Row-Level Security Policies for Qdrant Tenancy

This guide provides PostgreSQL row-level security (RLS) policy snippets that mirror the tenancy rules inside the Qdrant Gateway, ensuring consistent access control across both systems.

## Overview

When implementing a multi-tenant application with both Supabase (PostgreSQL) and Qdrant, it's critical to maintain consistent access control. These snippets demonstrate how to create policies that:

1. Restrict access based on tenant ID
2. Allow service accounts selective access
3. Handle read vs. write permissions separately
4. Support team-based access within tenants

## Basic Table Setup

```sql
-- Vector store metadata table
CREATE TABLE vector_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  tenant_id UUID NOT NULL REFERENCES auth.tenants(id),
  collection_name TEXT NOT NULL UNIQUE,
  description TEXT,
  embedding_model TEXT NOT NULL,
  dimensions INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),
  is_public BOOLEAN DEFAULT FALSE
);

-- Documents/chunks for vector store
CREATE TABLE vector_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID NOT NULL REFERENCES vector_collections(id) ON DELETE CASCADE,
  document_id TEXT NOT NULL,
  chunk_id TEXT NOT NULL,
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  tenant_id UUID NOT NULL REFERENCES auth.tenants(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  embedding vector(1536), -- Adjust dimension as needed
  UNIQUE(collection_id, document_id, chunk_id)
);
```

## Enable Row-Level Security

```sql
-- Enable RLS on tables
ALTER TABLE vector_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE vector_documents ENABLE ROW LEVEL SECURITY;

-- Create default deny policies
CREATE POLICY "deny all by default" ON vector_collections 
  USING (false);
  
CREATE POLICY "deny all by default" ON vector_documents 
  USING (false);
```

## Tenant Access Policies

```sql
-- Allow users to read collections in their tenant
CREATE POLICY "users can read their tenant's collections" ON vector_collections
  FOR SELECT
  USING (
    auth.jwt() ->> 'tenant_id' = tenant_id::text
    OR
    is_public = true
  );

-- Allow users to read documents in their tenant
CREATE POLICY "users can read their tenant's documents" ON vector_documents
  FOR SELECT
  USING (
    auth.jwt() ->> 'tenant_id' = tenant_id::text
    OR
    collection_id IN (
      SELECT id FROM vector_collections WHERE is_public = true
    )
  );

-- Allow users to insert documents in their tenant
CREATE POLICY "users can insert into their tenant's collections" ON vector_documents
  FOR INSERT
  WITH CHECK (
    auth.jwt() ->> 'tenant_id' = tenant_id::text
    AND
    collection_id IN (
      SELECT id FROM vector_collections 
      WHERE tenant_id::text = auth.jwt() ->> 'tenant_id'
    )
  );
```

## Service Account Access

```sql
-- Allow service accounts to access all collections
CREATE POLICY "service accounts can access all collections" ON vector_collections
  USING (
    auth.jwt() ->> 'role' = 'service_role'
  );

-- Allow service accounts to access all documents
CREATE POLICY "service accounts can access all documents" ON vector_documents
  USING (
    auth.jwt() ->> 'role' = 'service_role'
  );
```

## Team-Based Access Within Tenants

```sql
-- Allow team access to collections
CREATE POLICY "team members can access their collections" ON vector_collections
  FOR SELECT
  USING (
    -- Check if user is in the team that owns this collection
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN collection_teams ct ON tm.team_id = ct.team_id
      WHERE tm.user_id = auth.uid()
      AND ct.collection_id = vector_collections.id
    )
  );

-- Allow team access to documents
CREATE POLICY "team members can access their documents" ON vector_documents
  FOR SELECT
  USING (
    -- Check if user is in the team that owns the collection of this document
    EXISTS (
      SELECT 1 FROM team_members tm
      JOIN collection_teams ct ON tm.team_id = ct.team_id
      WHERE tm.user_id = auth.uid()
      AND ct.collection_id = vector_documents.collection_id
    )
  );
```

## Sync Functions for Qdrant Tenancy

These database functions help maintain consistency between PostgreSQL RLS and Qdrant tenancy:

```sql
-- Function to sync collection access to Qdrant
CREATE OR REPLACE FUNCTION sync_collection_to_qdrant()
RETURNS TRIGGER AS $$
BEGIN
  -- Call to Qdrant Gateway API to update collection access
  PERFORM http_post(
    'http://qdrant-gateway:8000/api/collections/sync',
    json_build_object(
      'collection_name', NEW.collection_name,
      'tenant_id', NEW.tenant_id,
      'is_public', NEW.is_public
    )::jsonb,
    'application/json',
    NULL,
    1000 -- Timeout in ms
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to maintain sync
CREATE TRIGGER sync_collection_tenancy_trigger
AFTER INSERT OR UPDATE ON vector_collections
FOR EACH ROW
EXECUTE FUNCTION sync_collection_to_qdrant();
```

## Qdrant Gateway Implementation

To implement corresponding tenancy in Qdrant Gateway, your middleware should:

1. Extract tenant ID from the JWT token
2. Verify collection access against PostgreSQL or a cached version
3. Apply collection filtering before proxying to Qdrant

The middleware code would look something like:

```python
@app.middleware("http")
async def tenant_middleware(request, call_next):
    # Extract JWT token from header
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        claims = decode_jwt(token)
        
        # Extract tenant_id
        tenant_id = claims.get("tenant_id")
        user_id = claims.get("sub")
        role = claims.get("role")
        
        # Skip tenant check for service accounts
        if role == "service_role":
            return await call_next(request)
            
        # For search/retrieve operations, check collection access
        if request.url.path.startswith("/collections/") and request.method in ["GET", "POST"]:
            collection_name = extract_collection_from_path(request.url.path)
            
            # Check if user has access to this collection
            has_access = await check_collection_access(collection_name, tenant_id, user_id)
            if not has_access:
                return JSONResponse(
                    status_code=403,
                    content={"error": "Access denied to this collection"}
                )
                
    return await call_next(request)
```

## Best Practices

1. **Cache Access Decisions**: To avoid database lookups on every request
2. **Consistent JWT Claims**: Ensure both Supabase and Qdrant Gateway use identical JWT verification
3. **Audit Logging**: Log access decisions for security review
4. **Periodic Reconciliation**: Run a job to verify Qdrant and PostgreSQL permissions stay in sync
5. **Test Across Boundaries**: Verify tenancy isolation in both systems with integration tests

## Example JWT Payload

```json
{
  "aud": "authenticated",
  "exp": 1716841045,
  "sub": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "email": "user@example.com",
  "tenant_id": "e1b3a9c2-d54f-4e91-b07c-02c82f63c3a4",
  "role": "authenticated",
  "teams": ["team-1", "team-2"]
}
```

This JWT structure can be used by both Supabase (through PostgreSQL RLS) and your Qdrant Gateway to make consistent access decisions.