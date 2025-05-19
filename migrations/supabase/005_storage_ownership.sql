-- Grant ownership of storage schema and objects to supabase_storage_admin
ALTER SCHEMA storage OWNER TO supabase_storage_admin;

-- Change ownership of tables
ALTER TABLE storage.objects OWNER TO supabase_storage_admin;
ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;

-- Grant superuser privileges to storage admin temporarily (be careful with this)
ALTER ROLE supabase_storage_admin WITH SUPERUSER;

-- Make sure all future objects in storage schema are owned by supabase_storage_admin
ALTER DEFAULT PRIVILEGES IN SCHEMA storage
  GRANT ALL ON TABLES TO supabase_storage_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA storage
  GRANT ALL ON SEQUENCES TO supabase_storage_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA storage
  GRANT EXECUTE ON FUNCTIONS TO supabase_storage_admin;
