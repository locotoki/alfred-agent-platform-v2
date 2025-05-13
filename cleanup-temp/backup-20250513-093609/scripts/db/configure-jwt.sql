-- Script to configure JWT settings in PostgREST
-- This sets the JWT secret in the PostgreSQL database configuration

-- Store the JWT secret in the database config
ALTER DATABASE postgres SET "app.jwt_secret" TO 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o';

-- Create a function to sign JWT tokens
CREATE OR REPLACE FUNCTION public.sign_jwt(payload json) RETURNS text AS $$
DECLARE
  secret text := current_setting('app.jwt_secret', true);
BEGIN
  RETURN pgjwt.sign(payload, secret);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to verify JWT tokens
CREATE OR REPLACE FUNCTION public.verify_jwt(token text) RETURNS table(header json, payload json, valid boolean) AS $$
DECLARE
  secret text := current_setting('app.jwt_secret', true);
BEGIN
  RETURN SELECT * FROM pgjwt.verify(token, secret);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate a test JWT token with service_role permissions
CREATE OR REPLACE FUNCTION public.generate_service_token() RETURNS TEXT AS $$
DECLARE
  token TEXT;
BEGIN
  SELECT public.sign_jwt(
    json_build_object(
      'role', 'service_role',
      'iat', extract(epoch from now())::integer,
      'exp', extract(epoch from now() + interval '1 year')::integer
    )
  ) INTO token;
  
  RETURN token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant access to the functions
GRANT EXECUTE ON FUNCTION public.sign_jwt TO authenticated;
GRANT EXECUTE ON FUNCTION public.sign_jwt TO service_role;
GRANT EXECUTE ON FUNCTION public.verify_jwt TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_jwt TO service_role;
GRANT EXECUTE ON FUNCTION public.generate_service_token TO service_role;

-- Enable access to RPC functions
COMMENT ON FUNCTION public.verify_jwt IS 'Verifies a JWT token';
COMMENT ON FUNCTION public.sign_jwt IS 'Signs a payload and returns a JWT token';
COMMENT ON FUNCTION public.generate_service_token IS 'Generates a service role JWT token';

-- Test the token generation
SELECT public.generate_service_token() AS new_service_token;