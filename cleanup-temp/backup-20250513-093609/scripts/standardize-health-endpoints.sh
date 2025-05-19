#!/bin/bash
# Script to standardize health check endpoints to /health across the Alfred Agent Platform v2

# Make a backup of the docker compose file
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
COMPOSE_FILE="/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml"
BACKUP_FILE="${COMPOSE_FILE}.bak-${TIMESTAMP}"

echo "Creating backup of docker-compose-clean.yml to ${BACKUP_FILE}"
cp ${COMPOSE_FILE} ${BACKUP_FILE}

# Function to update health check endpoints in the docker-compose file
update_health_checks() {
    # Update /healthz to /health
    sed -i 's|localhost:[0-9]*/healthz|localhost:&PORT/health|g' ${COMPOSE_FILE}
    sed -i 's|PORT/health|health|g' ${COMPOSE_FILE}

    # Update specific patterns to use /health endpoint
    sed -i 's|"CMD-SHELL", "wget -q -O - http://localhost:8501/healthz|"CMD-SHELL", "wget -q -O - http://localhost:8501/health|g' ${COMPOSE_FILE}
    sed -i 's|"CMD-SHELL", "wget -q -O - http://localhost:8000/healthz|"CMD-SHELL", "wget -q -O - http://localhost:8000/health|g' ${COMPOSE_FILE}
    sed -i 's|"CMD-SHELL", "wget -q -O - http://localhost:80/healthz|"CMD-SHELL", "wget -q -O - http://localhost:80/health|g' ${COMPOSE_FILE}
    sed -i 's|"CMD", "curl", "-f", "http://localhost:6333/healthz"|"CMD", "curl", "-f", "http://localhost:6333/health"|g' ${COMPOSE_FILE}

    # Update monitoring metrics endpoints to use /health where appropriate
    # Note: Some monitoring tools use /metrics as per Prometheus standards, which we'll keep
}

# Create a script to add health endpoints to services
create_health_endpoint_patch() {
    cat > /home/locotoki/projects/alfred-agent-platform-v2/patches/add-health-endpoints.py << 'EOL'
#!/usr/bin/env python3
"""
Script to add standardized health endpoints to FastAPI services.
This script adds a /health endpoint to services that only have /healthz.
"""
import os
import re
import glob
from pathlib import Path

def process_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # Check if file has FastAPI and /healthz but no /health endpoint
    if 'fastapi' in content.lower() and '/healthz' in content and '/health' not in content:
        print(f"Processing {file_path}...")

        # Look for @app.get("/healthz") pattern
        healthz_pattern = r'@app\.get\(["\']\/healthz["\']\)'
        health_endpoint = '@app.get("/health")\nasync def health():\n    return {"status": "healthy"}\n\n'

        # Check if we already have a healthz function we can duplicate
        if re.search(healthz_pattern, content):
            # Extract the entire healthz function
            healthz_func_pattern = r'(@app\.get\(["\']\/healthz["\']\).*?def.*?\(.*?\).*?return.*?})'
            healthz_func_match = re.search(healthz_func_pattern, content, re.DOTALL)

            if healthz_func_match:
                healthz_func = healthz_func_match.group(1)
                # Create a health function based on the healthz function
                health_func = healthz_func.replace('/healthz', '/health')

                # Add the health function after the healthz function
                modified_content = content.replace(healthz_func, healthz_func + '\n\n' + health_func)

                with open(file_path, 'w') as f:
                    f.write(modified_content)

                print(f"Added /health endpoint to {file_path}")
                return True

        # If we couldn't find a healthz function to duplicate, add a simple health endpoint
        # Find the right place to add the endpoint
        if '@app.get' in content:
            # Add after the first @app.get
            modified_content = re.sub(
                r'(@app\.get\(.*?\).*?def.*?\(.*?\).*?})',
                r'\1\n\n' + health_endpoint,
                content,
                count=1,
                flags=re.DOTALL
            )

            with open(file_path, 'w') as f:
                f.write(modified_content)

            print(f"Added /health endpoint to {file_path}")
            return True

    return False

def scan_services():
    services_dir = '/home/locotoki/projects/alfred-agent-platform-v2/services'
    agents_dir = '/home/locotoki/projects/alfred-agent-platform-v2/agents'

    modified_files = []

    # Process main.py files in services directory
    for main_py in glob.glob(f"{services_dir}/**/main.py", recursive=True):
        if process_file(main_py):
            modified_files.append(main_py)

    # Process agent.py files in agents directory
    for agent_py in glob.glob(f"{agents_dir}/**/agent.py", recursive=True):
        if process_file(agent_py):
            modified_files.append(agent_py)

    return modified_files

if __name__ == "__main__":
    modified_files = scan_services()

    if modified_files:
        print("\nModified files:")
        for file in modified_files:
            print(f"- {file}")
        print("\nPlease verify the changes and rebuild affected services.")
    else:
        print("No files needed modifications.")
EOL

    chmod +x /home/locotoki/projects/alfred-agent-platform-v2/patches/add-health-endpoints.py
    echo "Created health endpoint patch script at patches/add-health-endpoints.py"
}

# Execute the update
echo "Standardizing health check endpoints to /health in docker-compose-clean.yml..."
update_health_checks

# Create the patch script
echo "Creating patch script to add health endpoints to services..."
mkdir -p /home/locotoki/projects/alfred-agent-platform-v2/patches
create_health_endpoint_patch

echo "
=================================================================
Health Check Standardization Complete!
=================================================================

Changes made:
1. Updated Docker Compose health checks to use /health endpoint
2. Created a patch script to add /health endpoints to services

Next steps:
1. Run the patch script to update service code:
   python3 /home/locotoki/projects/alfred-agent-platform-v2/patches/add-health-endpoints.py

2. Restart services to apply configuration changes:
   ./start-platform.sh -a restart

NOTE: Services may still show as unhealthy if they don't
      implement the /health endpoint. Check the logs and
      manually update those services as needed.
"
