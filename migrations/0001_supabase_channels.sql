create publication architect_bus;

create table if not exists public.architect_in (
  id uuid primary key default gen_random_uuid(),
  data jsonb
);

create table if not exists public.architect_out (
  id uuid primary key default gen_random_uuid(),
  data jsonb
);

alter publication architect_bus add table public.architect_in, public.architect_out;