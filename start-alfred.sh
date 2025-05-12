#!/bin/bash

# start-alfred.sh - Streamlined startup script for Alfred Agent Platform v2
# This script uses docker-compose.combined-fixed.yml as the configuration file
# 
# This script provides a simple interface to start the Alfred Agent Platform
# with different combinations of services.

# Display ASCII art banner
cat << "EOF"
    _    _  __               _   
   / \  | |/ _|_ __ ___  __| |  
  / _ \ | | |_| '__/ _ \/ _` |  
 / ___ \| |  _| | |  __/ (_| |  
/_/   \_\_|_| |_|  \___|\__,_|  
                               
 Agent Platform v2
EOF

# Function to display help
show_help() {
    echo -e "\nUsage: ./start-alfred.sh [options]"
    echo -e "\nOptions:"
    echo "  --all          Start all services (default)"
    echo "  --core         Start only core services (Redis, Qdrant, PubSub, Supabase)"
    echo "  --atlas        Start only Atlas services (RAG Gateway, Worker)"
    echo "  --agents       Start only agent services (Alfred Bot, Social Intel, etc.)"
    echo "  --ui           Start only UI services (Mission Control)"
    echo "  --monitoring   Start only monitoring services (Prometheus, Grafana)"
    echo "  --minimal      Start minimal set of services for development"
    echo "  --down         Stop all services"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./start-alfred.sh --all"
    echo "  ./start-alfred.sh --core --atlas --ui"
    echo "  ./start-alfred.sh --down"
    exit 0
}

# Create network if it doesn't exist
create_network() {
    echo "Creating network..."
    docker network create alfred-network 2>/dev/null || true
}

# Function to start all services
start_all() {
    echo "Starting all Alfred services..."
    make start-all
}

# Function to stop all services
stop_all() {
    echo "Stopping all Alfred services..."
    make stop
}

# Function to start core services
start_core() {
    echo "Starting core services..."
    make up-core
}

# Function to start Atlas services
start_atlas() {
    echo "Starting Atlas services..."
    make up-atlas
}

# Function to start agent services
start_agents() {
    echo "Starting agent services..."
    make up-agents
}

# Function to start UI services
start_ui() {
    echo "Starting UI services..."
    make up-ui
}

# Function to start monitoring services
start_monitoring() {
    echo "Starting monitoring services..."
    make up-monitoring
}

# Function to start minimal set of services
start_minimal() {
    echo "Starting minimal services for development..."
    make up-core up-atlas up-ui
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    # No arguments provided, start all services
    create_network
    start_all
    exit 0
fi

# Process options
start_components=()
while [ $# -gt 0 ]; do
    case "$1" in
        --all)
            create_network
            start_all
            exit 0
            ;;
        --core)
            start_components+=("core")
            ;;
        --atlas)
            start_components+=("atlas")
            ;;
        --agents)
            start_components+=("agents")
            ;;
        --ui)
            start_components+=("ui")
            ;;
        --monitoring)
            start_components+=("monitoring")
            ;;
        --minimal)
            create_network
            start_minimal
            exit 0
            ;;
        --down)
            stop_all
            exit 0
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
    shift
done

# Start selected components
if [ ${#start_components[@]} -gt 0 ]; then
    create_network
    for component in "${start_components[@]}"; do
        case "$component" in
            core)
                start_core
                ;;
            atlas)
                start_atlas
                ;;
            agents)
                start_agents
                ;;
            ui)
                start_ui
                ;;
            monitoring)
                start_monitoring
                ;;
        esac
    done
    
    echo -e "\nSelected components started successfully!"
    echo "Access URLs:"
    echo "  Mission Control: http://localhost:3007"
    echo "  Atlas RAG Gateway: http://localhost:8501"
    echo "  Atlas Worker: http://localhost:8000"
    echo "  Prometheus: http://localhost:9090"
    echo "  Grafana: http://localhost:3005 (login: admin/admin)"
    echo "  Alfred Bot: http://localhost:8011"
    echo "  Alfred Orchestrator: http://localhost:8012"
fi