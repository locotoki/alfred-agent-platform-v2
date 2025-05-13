-- First drop existing policies that might conflict
DROP POLICY IF EXISTS service_role_all_architect_in ON public.architect_in;
DROP POLICY IF EXISTS service_role_all_architect_out ON public.architect_out;
DROP POLICY IF EXISTS anon_read_architect_out ON public.architect_out;
DROP POLICY IF EXISTS service_role_all_test ON public.service_role_test;

-- Create simplified policies
CREATE POLICY service_role_all_architect_in ON public.architect_in FOR ALL USING (true);
CREATE POLICY service_role_all_architect_out ON public.architect_out FOR ALL USING (true);
CREATE POLICY anon_read_architect_out ON public.architect_out FOR SELECT USING (true);
CREATE POLICY service_role_all_test ON public.service_role_test FOR ALL USING (true);

-- Verify the auth function exists
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

-- Create a public test function
CREATE OR REPLACE FUNCTION public.test_auth() RETURNS TEXT AS $$
BEGIN
  RETURN 'Authentication test: Role = ' || coalesce(current_setting('request.jwt.claim.role', true), 'none');
EXCEPTION WHEN OTHERS THEN
  RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant access to everyone
GRANT EXECUTE ON FUNCTION public.test_auth TO PUBLIC;
