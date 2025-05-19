#!/bin/bash
# env-audit.sh - Script to audit environment variables across all services
# This script extracts environment variables from docker-compose files and service code

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Environment Variables Audit ===${NC}"
echo "Scanning docker-compose files and services for environment variables..."

# Output file
OUTPUT_FILE="env-audit-results.md"

# Create or clear the output file
echo "# Environment Variables Audit" > $OUTPUT_FILE
echo "Generated on: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "This document catalogs all environment variables used across services in the Alfred Agent Platform." >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Function to extract environment variables from a docker-compose file
extract_from_compose() {
    local file=$1
    echo -e "${YELLOW}Scanning $file...${NC}"

    echo "## Variables from $file" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "| Service | Variable | Default Value | Required | Purpose |" >> $OUTPUT_FILE
    echo "|---------|----------|---------------|----------|---------|" >> $OUTPUT_FILE

    # Extract service and environment sections
    services=$(grep -A1 "services:" $file | tail -1 | sed 's/[[:space:]]*//g')

    # If no services found directly, try to find all service sections
    if [ -z "$services" ]; then
        service_names=$(grep -A1 "^[[:space:]]*[a-zA-Z0-9_-]*:" $file | grep -v ":" | sed 's/[[:space:]]*//g' | sort | uniq)

        for service in $service_names; do
            # Extract environment block
            env_block=$(sed -n "/^[[:space:]]*$service:/,/^[[:space:]]*[a-zA-Z0-9_-]*:/p" $file | grep -A100 "environment:" | grep -v "environment:" | grep -B100 -m1 "^[[:space:]]*[a-zA-Z0-9_-]*:" | grep -v "^[[:space:]]*[a-zA-Z0-9_-]*:")

            # Process each environment variable
            echo "$env_block" | grep -v "^--$" | grep -v "^$" | while read -r line; do
                # Clean up the line
                clean_line=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//g' | sed 's/^[[:space:]]*//g')

                # Extract variable name and default value
                var_name=$(echo "$clean_line" | cut -d '=' -f1 | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                default_value=$(echo "$clean_line" | grep -q "=" && echo "$clean_line" | cut -d '=' -f2- | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g' || echo "")

                # Check if it uses variable substitution
                if [[ $default_value == *'${''}'* ]]; then
                    var_in_default=$(echo "$default_value" | grep -o '\${[^}]*}' | sed 's/\${//g' | sed 's/}//g' | cut -d ':' -f1)
                    default_after_colon=$(echo "$default_value" | grep -o '\${[^}]*}' | grep -q ':' && echo "$default_value" | grep -o '\${[^}]*}' | sed 's/\${[^:]*://g' | sed 's/}//g' || echo "")

                    if [ -n "$default_after_colon" ]; then
                        required="No"
                        default_value="$default_after_colon (from \${$var_in_default})"
                    else
                        required="Yes"
                        default_value="None (from \${$var_in_default})"
                    fi
                else
                    if [ -n "$default_value" ]; then
                        required="No"
                    else
                        required="Yes"
                        default_value="None"
                    fi
                fi

                # Add to output file
                echo "| $service | $var_name | $default_value | $required | |" >> $OUTPUT_FILE
            done
        done
    fi
}

# Function to search for environment variables in Python files
extract_from_python() {
    local directory=$1
    echo -e "${YELLOW}Scanning Python files in $directory...${NC}"

    echo "## Variables from Python code in $directory" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "| File | Variable | Default Value | Required | Purpose |" >> $OUTPUT_FILE
    echo "|------|----------|---------------|----------|---------|" >> $OUTPUT_FILE

    # Find all Python files and search for os.environ or os.getenv
    find "$directory" -name "*.py" -type f -exec grep -l "os\.environ\|os\.getenv" {} \; | while read -r file; do
        # Get relative path
        rel_file=${file#$directory/}

        # Extract lines with os.environ or os.getenv
        grep -n "os\.environ\|os\.getenv" "$file" | while read -r line; do
            line_num=$(echo "$line" | cut -d':' -f1)
            content=$(echo "$line" | cut -d':' -f2-)

            # Extract variable name
            var_name=$(echo "$content" | grep -o 'os\.environ\.\get\s*(\s*["'"'"']\([^"'"'"']*\)["'"'"']\|os\.getenv\s*(\s*["'"'"']\([^"'"'"']*\)["'"'"']\|os\.environ\[["'"'"']\([^"'"'"']*\)["'"'"']\]' | grep -o '["'"'"'][^"'"'"']*["'"'"']' | sed 's/^["'"'"']//g' | sed 's/["'"'"']$//g')

            # Check if there's a default value (for os.getenv or os.environ.get)
            if echo "$content" | grep -q 'os\.environ\.get\|os\.getenv'; then
                # Check if there's a second parameter (default value)
                if echo "$content" | grep -q 'os\.environ\.get\s*(\s*["'"'"'][^"'"'"']*["'"'"']\s*,\|os\.getenv\s*(\s*["'"'"'][^"'"'"']*["'"'"']\s*,'; then
                    default_value=$(echo "$content" | sed 's/.*os\.environ\.get\s*(\s*["'"'"'][^"'"'"']*["'"'"']\s*,\s*\([^)]*\).*/\1/g' | sed 's/.*os\.getenv\s*(\s*["'"'"'][^"'"'"']*["'"'"']\s*,\s*\([^)]*\).*/\1/g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                    required="No"
                else
                    default_value="None"
                    required="Yes"
                fi
            else
                # os.environ[] usage always requires the variable
                default_value="None"
                required="Yes"
            fi

            # Add to output file
            echo "| $rel_file:$line_num | $var_name | $default_value | $required | |" >> $OUTPUT_FILE
        done
    done
}

# Function to search for environment variables in JavaScript/TypeScript files
extract_from_js() {
    local directory=$1
    echo -e "${YELLOW}Scanning JS/TS files in $directory...${NC}"

    echo "## Variables from JS/TS code in $directory" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    echo "| File | Variable | Default Value | Required | Purpose |" >> $OUTPUT_FILE
    echo "|------|----------|---------------|----------|---------|" >> $OUTPUT_FILE

    # Find all JS/TS files and search for process.env
    find "$directory" -name "*.js" -o -name "*.ts" -type f -exec grep -l "process\.env" {} \; | while read -r file; do
        # Get relative path
        rel_file=${file#$directory/}

        # Extract lines with process.env
        grep -n "process\.env" "$file" | while read -r line; do
            line_num=$(echo "$line" | cut -d':' -f1)
            content=$(echo "$line" | cut -d':' -f2-)

            # Extract variable name
            var_name=$(echo "$content" | grep -o 'process\.env\.\([A-Za-z0-9_]*\)' | sed 's/process\.env\.\([A-Za-z0-9_]*\)/\1/g')

            # Check if there's a default value using || or ??
            if echo "$content" | grep -q 'process\.env\.[A-Za-z0-9_]*\s*[|?][|?]\s*'; then
                default_value=$(echo "$content" | sed 's/.*process\.env\.[A-Za-z0-9_]*\s*[|?][|?]\s*\([^;,)]*\).*/\1/g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                required="No"
            else
                default_value="None"
                required="Yes"
            fi

            # Add to output file
            echo "| $rel_file:$line_num | $var_name | $default_value | $required | |" >> $OUTPUT_FILE
        done
    done
}

# Extract variables from docker-compose files
echo -e "${GREEN}Scanning Docker Compose files...${NC}"
extract_from_compose "docker-compose.yml"
extract_from_compose "docker-compose.dev.yml"

# Find all override files
find . -name "docker-compose.override*.yml" -type f | while read -r compose_file; do
    extract_from_compose "$compose_file"
done

# Extract variables from Python services
echo -e "${GREEN}Scanning Python services...${NC}"
find ./services -mindepth 1 -maxdepth 1 -type d | while read -r service_dir; do
    # Check if it contains Python files
    if find "$service_dir" -name "*.py" -type f | grep -q .; then
        extract_from_python "$service_dir"
    fi
done

# Extract variables from Python agents
echo -e "${GREEN}Scanning Python agents...${NC}"
find ./agents -mindepth 1 -maxdepth 1 -type d | while read -r agent_dir; do
    # Check if it contains Python files
    if find "$agent_dir" -name "*.py" -type f | grep -q .; then
        extract_from_python "$agent_dir"
    fi
done

# Extract variables from JS/TS services
echo -e "${GREEN}Scanning JavaScript/TypeScript services...${NC}"
find ./services -mindepth 1 -maxdepth 1 -type d | while read -r service_dir; do
    # Check if it contains JS/TS files
    if find "$service_dir" -name "*.js" -o -name "*.ts" -type f | grep -q .; then
        extract_from_js "$service_dir"
    fi
done

echo -e "${GREEN}Audit complete! Results saved to ${YELLOW}$OUTPUT_FILE${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Review the audit results and fill in the Purpose column"
echo -e "2. Create a centralized .env.example file"
echo -e "3. Develop an environment validation script"
