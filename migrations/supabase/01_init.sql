-- Initial database setup
CREATE SCHEMA IF NOT EXISTS public;

-- Create a basic users table
CREATE TABLE IF NOT EXISTS public.users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Basic permissions
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
