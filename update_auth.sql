-- Update auth.config with the new JWT secret if the table exists
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'auth' 
    AND table_name = 'config'
  ) THEN
    UPDATE auth.config SET jwt_secret = 'Dch9y6o9ih/DrzAjUtYS9a3/pEw+v8MFy8k+LYBv0uk=';
    RAISE NOTICE 'Updated JWT secret in auth.config';
  ELSE
    RAISE NOTICE 'auth.config table does not exist';
  END IF;
END $$;

-- Set the database parameter
ALTER DATABASE postgres SET "app.jwt_secret" TO 'Dch9y6o9ih/DrzAjUtYS9a3/pEw+v8MFy8k+LYBv0uk=';
