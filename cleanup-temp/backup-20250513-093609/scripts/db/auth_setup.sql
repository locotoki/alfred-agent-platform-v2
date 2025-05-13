-- Set the JWT secret as a database parameter
ALTER DATABASE postgres SET pgrst.jwt_secret TO 'Dch9y6o9ih/DrzAjUtYS9a3/pEw+v8MFy8k+LYBv0uk';

-- Create tables needed for authentication if they don't exist
CREATE SCHEMA IF NOT EXISTS auth;

-- Create basic users table if it doesn't exist
CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  role TEXT DEFAULT 'authenticated',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create a function to get the current authenticated user
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
BEGIN
  RETURN nullif(current_setting('request.jwt.claim.sub', true), '')::UUID;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- Create a function to get the current user's role
CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT AS $$
BEGIN
  RETURN coalesce(
    current_setting('request.jwt.claim.role', true),
    'anon'
  );
EXCEPTION WHEN OTHERS THEN
  RETURN 'anon';
END;
$$ LANGUAGE plpgsql STABLE;

-- Create tables for our application
CREATE TABLE IF NOT EXISTS public.architect_in (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.architect_out (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.service_role_test (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.architect_in ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.architect_out ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_role_test ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for service_role
CREATE POLICY IF NOT EXISTS service_role_all_architect_in 
  ON public.architect_in FOR ALL TO service_role USING (true);

CREATE POLICY IF NOT EXISTS service_role_all_architect_out 
  ON public.architect_out FOR ALL TO service_role USING (true);

CREATE POLICY IF NOT EXISTS anon_read_architect_out 
  ON public.architect_out FOR SELECT USING (true);

CREATE POLICY IF NOT EXISTS service_role_all_test 
  ON public.service_role_test FOR ALL TO service_role USING (true);

-- Grant permissions
GRANT ALL ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- Create a function to test authentication
CREATE OR REPLACE FUNCTION public.test_auth() RETURNS TEXT AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN 'Authentication successful as service_role';
  ELSIF auth.role() = 'anon' THEN
    RETURN 'Authentication successful as anon';
  ELSIF auth.role() = 'authenticated' THEN
    RETURN 'Authentication successful as authenticated user';
  ELSE
    RETURN 'Authentication failed. Current role: ' || auth.role();
  END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN 'Authentication error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to all roles
GRANT EXECUTE ON FUNCTION public.test_auth TO anon, authenticated, service_role;
