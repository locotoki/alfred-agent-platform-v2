FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM supabase/gotrue:v2.132.3

USER root

# Install PostgreSQL client
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

# Copy initialization script
COPY init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

# Create an entrypoint script that runs both the initialization and then the original service
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
n# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck


# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# The default command that will be executed if not overridden
CMD ["auth"]