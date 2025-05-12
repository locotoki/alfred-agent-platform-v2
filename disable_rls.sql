-- Disable Row Level Security for development
ALTER TABLE public.architect_in DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.architect_out DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_role_test DISABLE ROW LEVEL SECURITY;

-- Create a public function to verify disabled authentication
CREATE OR REPLACE FUNCTION public.check_auth_status() RETURNS TEXT AS $$
BEGIN
  RETURN 'Authentication disabled for development environment';
END;
$$ LANGUAGE plpgsql;

-- Grant access to everyone
GRANT EXECUTE ON FUNCTION public.check_auth_status TO PUBLIC;

-- Verify the anon role has full access
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;
