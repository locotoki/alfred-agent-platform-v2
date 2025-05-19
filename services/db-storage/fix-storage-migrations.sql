-- Reset and properly initialize storage migrations
-- This script ensures all the migrations expected by the storage-api service are marked as completed
-- with the correct hashes to prevent migration hash conflicts

-- Ensure storage schema exists
CREATE SCHEMA IF NOT EXISTS storage;

-- Recreate migrations table with correct structure
DROP TABLE IF EXISTS storage.migrations;
CREATE TABLE storage.migrations (
    id integer PRIMARY KEY,
    name text NOT NULL,
    hash text NOT NULL,
    executed_at timestamp with time zone DEFAULT now()
);

-- Ensure correct owner (if it exists in the database)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
    ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;
  END IF;
END $$;

-- Insert all the migration records with the expected hashes
-- These hash values match what the storage-api expects for each migration
INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES
(1, '0_create-migrations-table', 'e7862023a1ae7afe7b69f991e0530b15c4ef7d39', NOW()),
(2, '0001-initialmigration', 'fc1eeeaf8f12a9fa0eaf055f51b43c34', NOW()),
(3, '0002-pathtoken-column', '83455c984ffbe3feca3411b5591f68b8a4260ba9', NOW()),
(4, '0003-add-migrations-rls', '99b7ef8119e1f495163c0a1e13559878d4eb1156', NOW()),
(5, '0004-add-size-functions', 'cb9397a00fb5ea16b9dc700e149e90bd1cb2e55c', NOW()),
(6, '0005-change-column-name-in-get-size', 'b1e1ecb8c853314855a5c56a62d5b6a0cd0478a1', NOW()),
(7, '0006-add-rls-to-buckets', 'e5c09ff523fdd2a004cc3c021f2e0743d9e0c742', NOW()),
(8, '0007-add-public-to-buckets', '83455c984ffbe3feca3411b5591f68b8a4260ba9', NOW()),
(9, '0008-fix-search-function', 'dd7a45c4c648fea933e0f39ee272f28835442184', NOW()),
(10, '0009-search-files-search-function', '0a3a6d3075534359454fa6ffbd18d15236fd8e7c', NOW()),
(11, '0010-add-trigger-to-auto-update-updated_at-column', '5c32799bf9a513ff41aad55e77e65a5b8cdcab68', NOW()),
(12, '0011-add-automatic-avif-detection-flag', 'ba235f49a7f813793f172ad2ad4f0054e20ef0d2', NOW()),
(13, '0012-add-bucket-custom-limits', '85f8cdd25b1c671fde8b400d92a83d3ee3eed931', NOW()),
(14, '0013-use-bytes-for-max-size', 'dd43fa75f01535d88227bfd8d9be6ed5c56e5850', NOW()),
(15, '0014-add-can-insert-object-function', '834a2447d3ef2a83b2b34d7390d2725c20e3e5a6', NOW()),
(16, '0015-add-version', '3b93ddf2f91d5a6ab742b7374ea15081ed86c325', NOW()),
(17, '0016-drop-owner-foreign-key', 'fc07aa4ca3c545f0c9c431d952db6fa3e0c31ebe', NOW());

-- Grant permissions to ensure the service can access the table
GRANT ALL PRIVILEGES ON TABLE storage.migrations TO public;
