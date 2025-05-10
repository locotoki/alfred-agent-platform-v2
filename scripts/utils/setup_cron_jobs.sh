#!/bin/bash

# Script to set up cron jobs for the platform

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Create cron log directory
mkdir -p "${PROJECT_ROOT}/logs/cron"

# Add cleanup job to run every 6 hours
(crontab -l 2>/dev/null; echo "0 */6 * * * cd ${PROJECT_ROOT} && /usr/bin/python3 ${SCRIPT_DIR}/cleanup_processed_messages.py >> ${PROJECT_ROOT}/logs/cron/cleanup.log 2>&1") | crontab -

# Add health check to run every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * cd ${PROJECT_ROOT} && /usr/bin/python3 ${SCRIPT_DIR}/service_health_check.py >> ${PROJECT_ROOT}/logs/cron/health_check.log 2>&1") | crontab -

echo "✅ Cron jobs configured successfully"
echo ""
echo "Current crontab:"
crontab -l
