FROM supabase/storage-api:v0.43.11

# Create a custom entrypoint script that modifies the built-in migration behavior
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set the startup command to our custom entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]