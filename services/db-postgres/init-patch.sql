-- This script patches missing extensions by conditionally creating them
-- Create extensions schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS extensions;

-- Fallback implementation for pgjwt if extension is not available
DO $$
BEGIN
    -- Check if pgjwt extension exists
    IF NOT EXISTS (
        SELECT 1
        FROM pg_extension
        WHERE extname = 'pgjwt'
    ) THEN
        -- Create simplified JWT functions in extensions schema if pgjwt is not available
        CREATE OR REPLACE FUNCTION extensions.url_encode(data bytea) RETURNS text AS $$
        BEGIN
            RETURN replace(replace(encode(data, 'base64'), '/', '_'), '+', '-');
        END;
        $$ LANGUAGE PLPGSQL;

        CREATE OR REPLACE FUNCTION extensions.url_decode(data text) RETURNS bytea AS $$
        BEGIN
            RETURN decode(replace(replace(data, '-', '+'), '_', '/'), 'base64');
        END;
        $$ LANGUAGE PLPGSQL;

        CREATE OR REPLACE FUNCTION extensions.algorithm_sign(signables text, secret text, algorithm text)
        RETURNS text AS $$
        WITH
            alg AS (
                SELECT CASE
                    WHEN algorithm = 'HS256' THEN 'sha256'
                    WHEN algorithm = 'HS384' THEN 'sha384'
                    WHEN algorithm = 'HS512' THEN 'sha512'
                    ELSE '' END AS id)
        SELECT url_encode(hmac(signables, secret, alg.id)) FROM alg;
        $$ LANGUAGE sql;

        CREATE OR REPLACE FUNCTION extensions.sign(payload json, secret text, algorithm text DEFAULT 'HS256')
        RETURNS text AS $$
        WITH
            header AS (
                SELECT extensions.url_encode(convert_to('{"alg":"' || algorithm || '","typ":"JWT"}', 'utf8')) AS data
            ),
            payload AS (
                SELECT extensions.url_encode(convert_to(payload::text, 'utf8')) AS data
            ),
            signables AS (
                SELECT header.data || '.' || payload.data AS data FROM header, payload
            )
        SELECT
            signables.data || '.' ||
            extensions.algorithm_sign(signables.data, secret, algorithm) FROM signables;
        $$ LANGUAGE sql;
        
        RAISE NOTICE 'Created fallback JWT functions in extensions schema';
    END IF;
END$$;