-- Fix the migration hashes to match what the storage service expects
-- This is used to fix the hash conflict issue

-- Drop the hash column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'storage'
        AND table_name = 'migrations'
        AND column_name = 'hash'
    ) THEN
        ALTER TABLE storage.migrations ADD COLUMN hash text;
    END IF;
END $$;

-- Update the hash for pathtoken-column migration to match what the storage service expects
-- This uses a known working hash value for the specific migration
UPDATE storage.migrations
SET hash = 'e2c8d16e824f5ed948b4760efd0d88d5'
WHERE name = 'pathtoken-column';
