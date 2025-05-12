-- Initial database setup
-- This is a placeholder migration file for Supabase initialization

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create auth schema
CREATE SCHEMA IF NOT EXISTS auth;
COMMENT ON SCHEMA auth IS 'Authentication schema for Supabase';

-- Create storage schema
CREATE SCHEMA IF NOT EXISTS storage;
COMMENT ON SCHEMA storage IS 'Storage schema for Supabase';

-- Create graphql schema
CREATE SCHEMA IF NOT EXISTS graphql_public;
COMMENT ON SCHEMA graphql_public IS 'GraphQL public schema for Supabase';

-- Create basic tables
CREATE TABLE IF NOT EXISTS public.alfred_agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.alfred_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES public.alfred_agents(id),
    content TEXT NOT NULL,
    is_from_user BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create sample admin user for Supabase Auth
INSERT INTO auth.users (
    instance_id,
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000001',
    'admin@example.com',
    crypt('password', gen_salt('bf')),
    now(),
    now(),
    now()
) ON CONFLICT DO NOTHING;

-- Add sample data for testing
INSERT INTO public.alfred_agents (name, description) VALUES
('Core Agent', 'Main orchestration agent'),
('RAG Agent', 'Retrieval augmented generation agent'),
('Finance Agent', 'Financial analysis agent'),
('Legal Agent', 'Legal compliance agent')
ON CONFLICT DO NOTHING;

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update timestamps
CREATE TRIGGER update_alfred_agents_timestamp
BEFORE UPDATE ON public.alfred_agents
FOR EACH ROW EXECUTE FUNCTION update_timestamp();