-- Create a service role user
CREATE ROLE service_role NOLOGIN;

-- Grant service_role permissions to access the architect_in and architect_out tables
GRANT SELECT, INSERT, UPDATE, DELETE ON public.architect_in TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.architect_out TO service_role;

-- Create database policies to allow service_role to access these tables
ALTER TABLE public.architect_in ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.architect_out ENABLE ROW LEVEL SECURITY;

CREATE POLICY architect_in_service_role_policy ON public.architect_in
  FOR ALL
  TO service_role
  USING (true);

CREATE POLICY architect_out_service_role_policy ON public.architect_out
  FOR ALL
  TO service_role
  USING (true);