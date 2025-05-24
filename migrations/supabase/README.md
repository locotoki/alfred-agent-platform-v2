This folder is mounted into the Postgres container at
`/docker-entrypoint-initdb.d/` so Supabase's bootstrap SQL can run.
Place any custom role-creation or extension scripts here.
