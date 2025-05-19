#!/bin/bash
# validate-env.sh - Script to validate environment variables
# This script checks if all required environment variables are set
# and validates their format where applicable

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print heading
echo -e "${BLUE}${BOLD}=== Alfred Agent Platform Environment Variables Validation ===${NC}"

# Function to check if a variable is set in the environment or .env file
check_var() {
    local var_name=$1
    local required=$2
    local default_value=$3
    local format_regex=$4
    local format_description=$5
    local service_name=$6

    # Check .env file first
    if [ -f .env ]; then
        value=$(grep "^${var_name}=" .env | cut -d '=' -f2-)
    else
        value=""
    fi

    # If not in .env, check environment variables
    if [ -z "$value" ]; then
        value=${!var_name}
    fi

    # Format the service name display if provided
    local service_display=""
    if [ -n "$service_name" ]; then
        service_display=" [${service_name}]"
    fi

    # Check if the variable is set
    if [ -z "$value" ]; then
        if [ "$required" = "true" ]; then
            echo -e "${RED}ERROR: Required variable $var_name$service_display is not set${NC}"
            return 1
        elif [ -n "$default_value" ]; then
            echo -e "${YELLOW}WARN: $var_name$service_display is not set, will use default value: $default_value${NC}"
            return 0
        else
            echo -e "${YELLOW}WARN: $var_name$service_display is not set${NC}"
            return 0
        fi
    else
        # Check if the value matches the expected format if provided
        if [ -n "$format_regex" ]; then
            if ! [[ "$value" =~ $format_regex ]]; then
                echo -e "${RED}ERROR: $var_name$service_display has invalid format. $format_description${NC}"
                return 1
            fi
        fi

        # If the value contains a variable reference like ${VAR}, check if the referenced var exists
        if [[ "$value" == *"\${"*"}"* ]]; then
            ref_var=$(echo "$value" | grep -o '\${[^}]*}' | sed 's/\${//g' | sed 's/}//g' | cut -d ':' -f1)
            ref_default=$(echo "$value" | grep -o '\${[^}]*}' | grep -q ':' && echo "$value" | grep -o '\${[^}]*}' | sed 's/\${[^:]*://g' | sed 's/}//g' || echo "")

            # Check if the referenced variable exists
            if [ -z "${!ref_var}" ]; then
                if [ -n "$ref_default" ]; then
                    echo -e "${YELLOW}WARN: $var_name$service_display references $ref_var which is not set, will use default: $ref_default${NC}"
                else
                    echo -e "${RED}ERROR: $var_name$service_display references $ref_var which is not set and has no default${NC}"
                    return 1
                fi
            fi
        fi

        echo -e "${GREEN}OK: $var_name$service_display is set${NC}"
        return 0
    fi
}

# Function to check URL format and optionally test connectivity
check_url() {
    local var_name=$1
    local required=$2
    local default_value=$3
    local test_connection=$4
    local service_name=$5

    # First check if the variable is set
    local url_value=""
    if [ -f .env ]; then
        url_value=$(grep "^${var_name}=" .env | cut -d '=' -f2-)
    fi

    if [ -z "$url_value" ]; then
        url_value=${!var_name}
    fi

    # Format the service name display if provided
    local service_display=""
    if [ -n "$service_name" ]; then
        service_display=" [${service_name}]"
    fi

    # Check if the variable is set
    if [ -z "$url_value" ]; then
        if [ "$required" = "true" ]; then
            echo -e "${RED}ERROR: Required URL variable $var_name$service_display is not set${NC}"
            return 1
        elif [ -n "$default_value" ]; then
            echo -e "${YELLOW}WARN: URL $var_name$service_display is not set, will use default: $default_value${NC}"
            return 0
        else
            echo -e "${YELLOW}WARN: URL $var_name$service_display is not set${NC}"
            return 0
        fi
    else
        # Check if the URL is valid
        if ! [[ "$url_value" =~ ^https?:// ]]; then
            echo -e "${RED}ERROR: $var_name$service_display does not have a valid URL format (should start with http:// or https://)${NC}"
            return 1
        fi

        # Test connection if requested
        if [ "$test_connection" = "true" ] && command -v curl &>/dev/null; then
            # Extract domain/host for hostname resolution test
            local domain=$(echo "$url_value" | sed -E 's|^https?://||' | cut -d/ -f1 | cut -d: -f1)

            # Skip connectivity test for localhost, Docker service names, or private IP addresses
            if [[ "$domain" == "localhost" ]] ||
               [[ "$domain" =~ ^[a-zA-Z0-9_-]+$ ]] || # Docker service name pattern
               [[ "$domain" =~ ^127\. ]] ||
               [[ "$domain" =~ ^10\. ]] ||
               [[ "$domain" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] ||
               [[ "$domain" =~ ^192\.168\. ]]; then
                echo -e "${GREEN}OK: $var_name$service_display is a valid URL format (connection test skipped for internal resource)${NC}"
            else
                echo -ne "${YELLOW}Testing connection to $var_name$service_display... ${NC}"
                if timeout 5 curl -s --head "$url_value" &>/dev/null; then
                    echo -e "${GREEN}OK${NC}"
                else
                    echo -e "${YELLOW}Failed${NC}"
                    echo -e "${YELLOW}WARN: Could not connect to $var_name=$url_value${NC}"
                    # Return 0 as this is just a warning, not an error
                    return 0
                fi
            fi
        else
            echo -e "${GREEN}OK: $var_name$service_display is a valid URL format${NC}"
        fi

        return 0
    fi
}

# Function to check API key format
check_api_key() {
    local var_name=$1
    local required=$2
    local key_prefix=$3
    local service_name=$4

    # First check if the variable is set
    local key_value=""
    if [ -f .env ]; then
        key_value=$(grep "^${var_name}=" .env | cut -d '=' -f2-)
    fi

    if [ -z "$key_value" ]; then
        key_value=${!var_name}
    fi

    # Format the service name display if provided
    local service_display=""
    if [ -n "$service_name" ]; then
        service_display=" [${service_name}]"
    fi

    # Check if the variable is set
    if [ -z "$key_value" ]; then
        if [ "$required" = "true" ]; then
            echo -e "${RED}ERROR: Required API key $var_name$service_display is not set${NC}"
            return 1
        else
            echo -e "${YELLOW}WARN: API key $var_name$service_display is not set${NC}"
            return 0
        fi
    else
        # For OpenAI API keys
        if [ -n "$key_prefix" ] && [[ "$key_value" != $key_prefix* ]]; then
            echo -e "${RED}ERROR: $var_name$service_display has invalid format (should start with $key_prefix)${NC}"
            return 1
        fi

        # Handle mock keys for development
        if [[ "$key_value" == *"mock-key"* ]] || [[ "$key_value" == *"placeholder"* ]]; then
            echo -e "${YELLOW}WARN: $var_name$service_display appears to be a mock key${NC}"
        else
            echo -e "${GREEN}OK: $var_name$service_display is set with correct format${NC}"
        fi

        return 0
    fi
}

# Function to validate service-specific variables
validate_service() {
    local service=$1
    local status=0

    echo -e "\n${BLUE}${BOLD}Validating environment variables for $service...${NC}"

    case "$service" in
        "social-intel")
            check_var "DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "REDIS_URL" false "redis://redis:6379" "" "" "$service" || status=1
            check_api_key "ALFRED_YOUTUBE_API_KEY" true "" "$service" || status=1
            check_url "SOCIAL_INTEL_URL" true "http://agent-social:9000" false "$service" || status=1
            check_url "ALFRED_MODEL_ROUTER_URL" false "http://model-router:8080" false "$service" || status=1
            check_url "ALFRED_RAG_URL" false "http://agent-rag:8501" false "$service" || status=1
            ;;
        "financial-tax")
            check_var "DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "REDIS_URL" false "redis://redis:6379" "" "" "$service" || status=1
            check_url "ALFRED_MODEL_ROUTER_URL" false "http://model-router:8080" false "$service" || status=1
            ;;
        "legal-compliance")
            check_var "DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "REDIS_URL" false "redis://redis:6379" "" "" "$service" || status=1
            check_url "ALFRED_MODEL_ROUTER_URL" false "http://model-router:8080" false "$service" || status=1
            ;;
        "alfred-bot")
            check_var "DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "REDIS_URL" false "redis://redis:6379" "" "" "$service" || status=1
            check_api_key "ALFRED_SLACK_BOT_TOKEN" true "xoxb-" "$service" || status=1
            check_var "ALFRED_SLACK_SIGNING_SECRET" true "" "" "" "$service" || status=1
            check_url "ALFRED_MODEL_ROUTER_URL" false "http://model-router:8080" false "$service" || status=1
            ;;
        "model-registry")
            check_var "DATABASE_URL" true "" "" "" "$service" || status=1
            check_url "OLLAMA_URL" false "http://llm-service:11434" false "$service" || status=1
            check_api_key "ALFRED_OPENAI_API_KEY" false "sk-" "$service" || status=1
            ;;
        "model-router")
            check_url "MODEL_REGISTRY_URL" false "http://model-registry:8079" false "$service" || status=1
            check_api_key "ALFRED_OPENAI_API_KEY" false "sk-" "$service" || status=1
            check_api_key "ALFRED_ANTHROPIC_API_KEY" false "" "$service" || status=1
            ;;
        "agent-rag")
            check_url "ALFRED_QDRANT_URL" false "http://vector-db:6333" false "$service" || status=1
            check_var "ALFRED_REDIS_URL" false "redis://redis:6379/0" "" "" "$service" || status=1
            check_url "ALFRED_MODEL_ROUTER_URL" false "http://model-router:8080" false "$service" || status=1
            check_var "ALFRED_RAG_API_KEY" false "social-key" "" "" "$service" || status=1
            check_var "ALFRED_RAG_COLLECTION" false "social-knowledge" "" "" "$service" || status=1
            ;;
        "agent-core")
            check_var "ALFRED_DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "ALFRED_REDIS_URL" false "redis://redis:6379" "" "" "$service" || status=1
            check_var "ALFRED_PUBSUB_EMULATOR_HOST" false "pubsub-emulator:8085" "" "" "$service" || status=1
            check_url "ALFRED_MODEL_ROUTER_URL" false "http://model-router:8080" false "$service" || status=1
            check_url "ALFRED_RAG_URL" false "http://agent-rag:8501" false "$service" || status=1
            ;;
        "ui-chat")
            check_url "ALFRED_API_URL" false "http://agent-core:8011" false "$service" || status=1
            check_url "ALFRED_MODEL_ROUTER_URL" false "http://model-router:8080" false "$service" || status=1
            check_var "STREAMLIT_SERVER_HEADLESS" true "true" "" "" "$service" || status=1
            ;;
        "ui-admin")
            check_url "ALFRED_API_URL" false "http://agent-core:8011" false "$service" || status=1
            check_url "ALFRED_RAG_URL" false "http://agent-rag:8501" false "$service" || status=1
            check_url "NEXT_PUBLIC_SOCIAL_INTEL_URL" false "http://agent-social:9000" false "$service" || status=1
            ;;
        "db-storage")
            check_var "DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "ANON_KEY" true "" "" "" "$service" || status=1
            check_var "SERVICE_ROLE_KEY" true "" "" "" "$service" || status=1
            ;;
        "db-auth")
            check_var "GOTRUE_DB_DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "GOTRUE_JWT_SECRET" true "" "" "" "$service" || status=1
            ;;
        "db-api")
            check_var "PGRST_DB_URI" true "" "" "" "$service" || status=1
            check_var "PGRST_JWT_SECRET" true "" "" "" "$service" || status=1
            ;;
        "core")
            # Core platform variables
            check_var "ALFRED_PROJECT_ID" false "alfred-agent-platform" "" "" "$service" || status=1
            check_var "ALFRED_ENVIRONMENT" false "development" "^(development|production|test)$" "Should be 'development', 'production', or 'test'" "$service" || status=1
            check_var "PUBSUB_EMULATOR_HOST" false "pubsub-emulator:8085" "" "" "$service" || status=1
            check_var "DATABASE_URL" true "" "" "" "$service" || status=1
            check_var "REDIS_URL" true "redis://redis:6379" "" "" "$service" || status=1
            ;;
        *)
            echo -e "${YELLOW}No specific validation rules for $service${NC}"
            ;;
    esac

    return $status
}

# Function to validate database connection strings
validate_db_connection() {
    local db_url=$1
    local db_name=$2
    local status=0

    # Check if the connection string seems valid
    if [[ ! "$db_url" =~ ^(postgresql|postgres):// ]]; then
        echo -e "${RED}ERROR: $db_name does not appear to be a valid PostgreSQL connection string${NC}"
        status=1
    fi

    # Extract host and port for more detailed checks
    local db_host=$(echo "$db_url" | sed -E 's|^postgresql://[^@]+@([^:/]+).*|\1|')
    local db_port=$(echo "$db_url" | sed -E 's|^postgresql://[^@]+@[^:]+:([0-9]+).*|\1|')

    if [[ -z "$db_host" ]]; then
        echo -e "${RED}ERROR: Could not extract host from $db_name${NC}"
        status=1
    fi

    if [[ -z "$db_port" ]]; then
        echo -e "${YELLOW}WARN: Could not extract port from $db_name, assuming default port 5432${NC}"
        db_port=5432
    fi

    echo -e "${GREEN}OK: $db_name appears to be properly formatted (host: $db_host, port: $db_port)${NC}"

    return $status
}

# Function to check for duplicate service URLs
check_for_duplicate_ports() {
    local status=0

    echo -e "\n${BLUE}${BOLD}Checking for potential port conflicts...${NC}"

    # Define an array of URL variables to check
    declare -a url_vars=(
        "ALFRED_API_URL"
        "ALFRED_MODEL_ROUTER_URL"
        "ALFRED_RAG_URL"
        "SOCIAL_INTEL_URL"
        "SOCIAL_INTEL_SERVICE_URL"
        "MODEL_REGISTRY_URL"
        "NEXT_PUBLIC_SOCIAL_INTEL_URL"
    )

    # Create associative arrays for ports and hosts
    declare -A port_to_vars
    declare -A host_port_pair

    for var in "${url_vars[@]}"; do
        local url_value=""
        if [ -f .env ]; then
            url_value=$(grep "^${var}=" .env | cut -d '=' -f2-)
        fi

        if [ -z "$url_value" ]; then
            url_value=${!var}
        fi

        if [ -n "$url_value" ]; then
            # Extract host and port
            local host=$(echo "$url_value" | sed -E 's|^https?://([^:/]+).*|\1|')
            local port=$(echo "$url_value" | sed -E 's|^https?://[^:]+:([0-9]+).*|\1|')

            if [ -z "$port" ]; then
                # Default ports for HTTP/HTTPS
                if [[ "$url_value" =~ ^https:// ]]; then
                    port=443
                else
                    port=80
                fi
            fi

            # Check for duplicate ports on the same host
            if [ -n "${host_port_pair[$host:$port]}" ]; then
                echo -e "${YELLOW}WARN: Possible port conflict detected: $host:$port is used by both ${host_port_pair[$host:$port]} and $var${NC}"
            else
                host_port_pair[$host:$port]=$var
            fi

            # Track which variables use the same port
            if [ -n "${port_to_vars[$port]}" ]; then
                port_to_vars[$port]="${port_to_vars[$port]}, $var"
            else
                port_to_vars[$port]=$var
            fi
        fi
    done

    # Check for port conflicts on localhost
    for port in "${!port_to_vars[@]}"; do
        if [ -n "${host_port_pair[localhost:$port]}" ] && [ -n "${host_port_pair[127.0.0.1:$port]}" ]; then
            echo -e "${YELLOW}WARN: Possible port conflict detected: port $port is used by both localhost and 127.0.0.1 (${port_to_vars[$port]})${NC}"
        fi

        # Check if a port is used by multiple variables with different hosts
        if [[ "${port_to_vars[$port]}" == *","* ]]; then
            num_vars=$(echo "${port_to_vars[$port]}" | tr ',' '\n' | wc -l)
            if [ "$num_vars" -gt 2 ]; then
                echo -e "${YELLOW}WARN: Port $port is used by multiple variables: ${port_to_vars[$port]}${NC}"
            fi
        fi
    done

    return $status
}

# Function to validate critical pairs of variables
validate_variable_pairs() {
    local status=0

    echo -e "\n${BLUE}${BOLD}Validating related variable pairs...${NC}"

    # Check DATABASE_URL and ALFRED_DATABASE_URL match
    if [ -n "$DATABASE_URL" ] && [ -n "$ALFRED_DATABASE_URL" ]; then
        if [ "$DATABASE_URL" != "$ALFRED_DATABASE_URL" ]; then
            echo -e "${RED}ERROR: DATABASE_URL and ALFRED_DATABASE_URL do not match${NC}"
            echo -e "  DATABASE_URL=$DATABASE_URL"
            echo -e "  ALFRED_DATABASE_URL=$ALFRED_DATABASE_URL"
            status=1
        else
            echo -e "${GREEN}OK: DATABASE_URL and ALFRED_DATABASE_URL match${NC}"
        fi
    fi

    # Check REDIS_URL and ALFRED_REDIS_URL match
    if [ -n "$REDIS_URL" ] && [ -n "$ALFRED_REDIS_URL" ]; then
        if [ "$REDIS_URL" != "$ALFRED_REDIS_URL" ]; then
            echo -e "${RED}ERROR: REDIS_URL and ALFRED_REDIS_URL do not match${NC}"
            echo -e "  REDIS_URL=$REDIS_URL"
            echo -e "  ALFRED_REDIS_URL=$ALFRED_REDIS_URL"
            status=1
        else
            echo -e "${GREEN}OK: REDIS_URL and ALFRED_REDIS_URL match${NC}"
        fi
    fi

    # Check PUBSUB_EMULATOR_HOST and ALFRED_PUBSUB_EMULATOR_HOST match
    if [ -n "$PUBSUB_EMULATOR_HOST" ] && [ -n "$ALFRED_PUBSUB_EMULATOR_HOST" ]; then
        if [ "$PUBSUB_EMULATOR_HOST" != "$ALFRED_PUBSUB_EMULATOR_HOST" ]; then
            echo -e "${RED}ERROR: PUBSUB_EMULATOR_HOST and ALFRED_PUBSUB_EMULATOR_HOST do not match${NC}"
            echo -e "  PUBSUB_EMULATOR_HOST=$PUBSUB_EMULATOR_HOST"
            echo -e "  ALFRED_PUBSUB_EMULATOR_HOST=$ALFRED_PUBSUB_EMULATOR_HOST"
            status=1
        else
            echo -e "${GREEN}OK: PUBSUB_EMULATOR_HOST and ALFRED_PUBSUB_EMULATOR_HOST match${NC}"
        fi
    fi

    # Check YOUTUBE_API_KEY and ALFRED_YOUTUBE_API_KEY match
    if [ -n "$YOUTUBE_API_KEY" ] && [ -n "$ALFRED_YOUTUBE_API_KEY" ]; then
        if [ "$YOUTUBE_API_KEY" != "$ALFRED_YOUTUBE_API_KEY" ]; then
            echo -e "${RED}ERROR: YOUTUBE_API_KEY and ALFRED_YOUTUBE_API_KEY do not match${NC}"
            echo -e "  YOUTUBE_API_KEY=$YOUTUBE_API_KEY"
            echo -e "  ALFRED_YOUTUBE_API_KEY=$ALFRED_YOUTUBE_API_KEY"
            status=1
        else
            echo -e "${GREEN}OK: YOUTUBE_API_KEY and ALFRED_YOUTUBE_API_KEY match${NC}"
        fi
    fi

    # Check OPENAI_API_KEY and ALFRED_OPENAI_API_KEY match
    if [ -n "$OPENAI_API_KEY" ] && [ -n "$ALFRED_OPENAI_API_KEY" ]; then
        if [ "$OPENAI_API_KEY" != "$ALFRED_OPENAI_API_KEY" ]; then
            echo -e "${RED}ERROR: OPENAI_API_KEY and ALFRED_OPENAI_API_KEY do not match${NC}"
            echo -e "  OPENAI_API_KEY=$OPENAI_API_KEY"
            echo -e "  ALFRED_OPENAI_API_KEY=$ALFRED_OPENAI_API_KEY"
            status=1
        else
            echo -e "${GREEN}OK: OPENAI_API_KEY and ALFRED_OPENAI_API_KEY match${NC}"
        fi
    fi

    # Check SLACK_BOT_TOKEN and ALFRED_SLACK_BOT_TOKEN match
    if [ -n "$SLACK_BOT_TOKEN" ] && [ -n "$ALFRED_SLACK_BOT_TOKEN" ]; then
        if [ "$SLACK_BOT_TOKEN" != "$ALFRED_SLACK_BOT_TOKEN" ]; then
            echo -e "${RED}ERROR: SLACK_BOT_TOKEN and ALFRED_SLACK_BOT_TOKEN do not match${NC}"
            echo -e "  SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN"
            echo -e "  ALFRED_SLACK_BOT_TOKEN=$ALFRED_SLACK_BOT_TOKEN"
            status=1
        else
            echo -e "${GREEN}OK: SLACK_BOT_TOKEN and ALFRED_SLACK_BOT_TOKEN match${NC}"
        fi
    fi

    # Check SLACK_SIGNING_SECRET and ALFRED_SLACK_SIGNING_SECRET match
    if [ -n "$SLACK_SIGNING_SECRET" ] && [ -n "$ALFRED_SLACK_SIGNING_SECRET" ]; then
        if [ "$SLACK_SIGNING_SECRET" != "$ALFRED_SLACK_SIGNING_SECRET" ]; then
            echo -e "${RED}ERROR: SLACK_SIGNING_SECRET and ALFRED_SLACK_SIGNING_SECRET do not match${NC}"
            echo -e "  SLACK_SIGNING_SECRET=$SLACK_SIGNING_SECRET"
            echo -e "  ALFRED_SLACK_SIGNING_SECRET=$ALFRED_SLACK_SIGNING_SECRET"
            status=1
        else
            echo -e "${GREEN}OK: SLACK_SIGNING_SECRET and ALFRED_SLACK_SIGNING_SECRET match${NC}"
        fi
    fi

    return $status
}

# Function to load .env file into environment
load_env() {
    if [ -f .env ]; then
        echo -e "${BLUE}Loading variables from .env file...${NC}"
        set -o allexport
        source .env
        set +o allexport
    else
        echo -e "${YELLOW}No .env file found. Using environment variables only.${NC}"

        # Check if .env.example exists and offer to copy it
        if [ -f .env.example ] && [ -t 1 ]; then
            echo -e "${YELLOW}Would you like to create a .env file from .env.example? (y/N)${NC}"
            read -r choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                cp .env.example .env
                echo -e "${GREEN}Created .env from .env.example. Please edit it with your values.${NC}"

                # Load the newly created .env file
                set -o allexport
                source .env
                set +o allexport
            fi
        fi
    fi
}

# Function to check for sensitive values in plaintext
check_for_sensitive_values() {
    local status=0

    echo -e "\n${BLUE}${BOLD}Checking for potentially sensitive values in plaintext...${NC}"

    # Check for variables with potentially sensitive values
    declare -a sensitive_vars=(
        "POSTGRES_PASSWORD"
        "ALFRED_OPENAI_API_KEY"
        "ALFRED_ANTHROPIC_API_KEY"
        "OPENAI_API_KEY"
        "SLACK_BOT_TOKEN"
        "SLACK_SIGNING_SECRET"
        "ALFRED_SLACK_BOT_TOKEN"
        "ALFRED_SLACK_SIGNING_SECRET"
        "DB_JWT_SECRET"
        "GOTRUE_JWT_SECRET"
        "PGRST_JWT_SECRET"
        "API_KEY_SALT"
        "ENCRYPTION_KEY"
        "GRAFANA_ADMIN_PASSWORD"
        "MONITORING_ADMIN_PASSWORD"
    )

    for var in "${sensitive_vars[@]}"; do
        local value=""
        if [ -f .env ]; then
            value=$(grep "^${var}=" .env | cut -d '=' -f2-)
        fi

        if [ -z "$value" ]; then
            value=${!var}
        fi

        if [ -n "$value" ]; then
            # Check for default or placeholder values
            if [[ "$value" == *"admin"* ]] ||
               [[ "$value" == *"password"* ]] ||
               [[ "$value" == *"postgres"* ]] ||
               [[ "$value" == *"development-only"* ]] ||
               [[ "$value" == *"dev-only"* ]] ||
               [[ "$value" == *"placeholder"* ]] ||
               [[ "$value" == *"mock"* ]]; then

                if [[ "$ALFRED_ENVIRONMENT" == "production" ]]; then
                    echo -e "${RED}ERROR: $var appears to have a default/test value in production environment: $value${NC}"
                    status=1
                else
                    echo -e "${YELLOW}WARN: $var appears to have a default/test value: $value${NC}"
                fi
            else
                # For non-default values, check for weak patterns
                if [[ ${#value} -lt 8 ]]; then
                    echo -e "${YELLOW}WARN: $var has a very short value (less than 8 characters)${NC}"
                elif [[ "$var" == *"PASSWORD"* ]] && ! [[ "$value" =~ [0-9] ]] && ! [[ "$value" =~ [A-Z] ]] && ! [[ "$value" =~ [a-z] ]]; then
                    echo -e "${YELLOW}WARN: $var appears to have a weak password (missing numbers, uppercase, or lowercase)${NC}"
                else
                    # Pass validation for strong secrets
                    echo -e "${GREEN}OK: $var appears to have a proper value set${NC}"
                fi
            fi
        fi
    done

    return $status
}

# Main function
main() {
    local status=0

    # Load environment variables from .env file
    load_env

    # Process arguments
    if [ "$#" -eq 0 ]; then
        # No specific service given, validate common variables
        echo -e "${BLUE}${BOLD}Validating common environment variables...${NC}"

        # Check common required variables
        check_var "DATABASE_URL" true "" "" "" "common" || status=1
        check_var "REDIS_URL" false "redis://redis:6379" "" "" "common" || status=1
        check_var "ALFRED_ENVIRONMENT" false "development" "^(development|production|test)$" "Should be 'development', 'production', or 'test'" "common" || status=1

        # For non-empty DATABASE_URL, validate its format
        if [ -n "$DATABASE_URL" ]; then
            validate_db_connection "$DATABASE_URL" "DATABASE_URL" || status=1
        fi

        # Check for duplicate ports
        check_for_duplicate_ports || status=1

        # Validate related variable pairs
        validate_variable_pairs || status=1

        # Check for sensitive values in plaintext
        check_for_sensitive_values || status=1

        # Check if specific services are requested in interactive mode
        if [ -t 1 ]; then
            echo -e "\n${YELLOW}Would you like to validate environment variables for specific services? (y/N)${NC}"
            read -r choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Enter space-separated service names (e.g., social-intel agent-core):${NC}"
                read -r services

                for service in $services; do
                    validate_service "$service" || status=1
                done
            fi
        fi
    else
        # Validate specific services
        for service in "$@"; do
            validate_service "$service" || status=1
        done
    fi

    # Print summary
    if [ $status -eq 0 ]; then
        echo -e "\n${GREEN}${BOLD}Environment validation passed!${NC}"
    else
        echo -e "\n${RED}${BOLD}Environment validation failed! Please fix the issues above.${NC}"
        echo -e "${YELLOW}Tip: Copy missing variables from .env.example to your .env file.${NC}"
        echo -e "${YELLOW}For more detailed information, see the Environment Variables Documentation:${NC}"
        echo -e "${YELLOW}  docs/ENVIRONMENT_VARIABLES.md${NC}"
    fi

    return $status
}

# Run the main function with all arguments
main "$@"
