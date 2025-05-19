-- Create migrations table
CREATE TABLE IF NOT EXISTS storage.migrations (
    id integer PRIMARY KEY,
    name text NOT NULL,
    executed_at timestamptz DEFAULT now()
);

-- Grant permissions
ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

-- Mark existing migrations as completed
INSERT INTO storage.migrations (id, name) VALUES
(1, 'add-public-to-buckets'),
(2, 'add-rls-to-buckets'),
(3, 'pathtoken-column')
ON CONFLICT (id) DO NOTHING;
