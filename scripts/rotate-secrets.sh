#!/bin/bash
# Script to check for and rotate secrets

echo "===== Checking for secrets in git history ====="
echo "This script will check for potential secrets in the git history."

# Check for potential secrets
echo "Scanning git history for potential secrets..."
git log -p | grep -E '(API_KEY|SECRET|TOKEN|PASSWORD|PASS=|KEY=)' > potential_secrets.txt

if [ -s potential_secrets.txt ]; then
  echo "⚠️ Potential secrets found in git history!"
  echo "Number of matches: $(wc -l < potential_secrets.txt)"
  echo "Sample entries (first 5):"
  head -5 potential_secrets.txt

  # Generate a list of environment variables to rotate
  echo "Creating list of environment variables to rotate..."
  grep -o -E '([A-Z_]+_API_KEY|[A-Z_]+_SECRET|[A-Z_]+_TOKEN|[A-Z_]+_PASSWORD)=[^ ]+' potential_secrets.txt | cut -d= -f1 | sort | uniq > secrets_to_rotate.txt

  echo "Variables that should be rotated:"
  cat secrets_to_rotate.txt

  # Clean up
  rm potential_secrets.txt
else
  echo "✅ No obvious secrets found in git history"
  rm potential_secrets.txt
fi

echo ""
echo "===== Secrets Rotation Procedure ====="
echo "For each variable listed above, follow these steps:"
echo ""
echo "1. Log in to the respective service portal"
echo "2. Create a new API key/token to replace the compromised one"
echo "3. Update the .env file with the new value"
echo "4. Update any CI/CD environments with the new value"
echo "5. Test the service with the new credentials"
echo "6. Revoke the old credential from the service portal"
echo ""
echo "For database passwords:"
echo "1. Create a database backup"
echo "2. Change the database user password"
echo "3. Update the password in .env files and CI/CD environments"
echo "4. Restart services to pick up the new password"
echo ""
echo "Additionally, consider:"
echo "1. Using git-filter-repo to remove sensitive data from history"
echo "2. Implementing a secrets management solution like HashiCorp Vault"
echo "3. Setting up GitGuardian or similar tool to prevent future leaks"
echo ""
echo "After rotating all secrets, restart the services:"
echo "docker compose down && docker compose up -d"
