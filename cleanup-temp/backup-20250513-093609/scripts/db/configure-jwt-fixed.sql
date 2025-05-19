-- Script to configure JWT settings in PostgREST
-- This sets the JWT secret in the PostgreSQL database configuration

-- Store the JWT secret in the database config
ALTER DATABASE postgres SET "app.jwt_secret" TO 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o';

-- Check if the pgjwt schema exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'pgjwt') THEN
        -- Create pgjwt schema if it doesn't exist
        CREATE SCHEMA pgjwt;

        -- Create basic JWT functions in pgjwt schema
        CREATE OR REPLACE FUNCTION pgjwt.sign(payload json, secret text) RETURNS text AS $$
        WITH
          header AS (
            SELECT
              encode(
                convert_to(
                  '{"alg":"HS256","typ":"JWT"}',
                  'utf8'
                ),
                'base64'
              ) AS data
          ),
          payload AS (
            SELECT
              encode(
                convert_to(
                  payload::text,
                  'utf8'
                ),
                'base64'
              ) AS data
          ),
          signables AS (
            SELECT
              header.data || '.' || payload.data AS data
            FROM header, payload
          )
        SELECT
          signables.data || '.' ||
          encode(
            hmac(
              signables.data,
              secret,
              'sha256'
            ),
            'base64'
          ) AS token
        FROM signables;
        $$ LANGUAGE sql;
    END IF;
END $$;

-- Create a function to create service role tokens
CREATE OR REPLACE FUNCTION public.generate_service_token() RETURNS TEXT AS $$
DECLARE
  payload json;
  secret text := current_setting('app.jwt_secret', true);
  token text;
BEGIN
  -- Create a payload for service_role
  payload := json_build_object(
    'role', 'service_role',
    'iat', extract(epoch from now())::integer,
    'exp', extract(epoch from now() + interval '1 year')::integer
  );

  -- Sign the token using HMAC SHA-256
  WITH
    header AS (
      SELECT
        encode(
          convert_to(
            '{"alg":"HS256","typ":"JWT"}',
            'utf8'
          ),
          'base64'
        ) AS data
    ),
    payload_encoded AS (
      SELECT
        encode(
          convert_to(
            payload::text,
            'utf8'
          ),
          'base64'
        ) AS data
    ),
    signables AS (
      SELECT
        header.data || '.' || payload_encoded.data AS data
      FROM header, payload_encoded
    )
  SELECT
    signables.data || '.' ||
    encode(
      hmac(
        signables.data,
        secret,
        'sha256'
      ),
      'base64'
    ) INTO token
  FROM signables;

  RETURN token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RLS test function
CREATE OR REPLACE FUNCTION public.test_auth() RETURNS TEXT AS $$
BEGIN
  -- If the role is service_role, return success
  IF current_setting('request.jwt.claim.role', 'anon') = 'service_role' THEN
    RETURN 'Authentication successful as service_role';
  ELSE
    RETURN 'Authentication failed. Role: ' || current_setting('request.jwt.claim.role', 'not set');
  END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN 'Authentication error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to the service_role
GRANT EXECUTE ON FUNCTION public.test_auth TO service_role;
GRANT EXECUTE ON FUNCTION public.test_auth TO anon;
GRANT EXECUTE ON FUNCTION public.generate_service_token TO service_role;

-- Test token generation
SELECT public.generate_service_token() AS new_service_token;
