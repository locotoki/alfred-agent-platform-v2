#!/usr/bin/env python3
"""
Script to set up Prometheus configuration for monitoring health checks.
This script creates or updates the Prometheus configuration to include
service discovery for all containers and scrape health check metrics.
"""
import os
import sys
import yaml

# Configuration
PROMETHEUS_CONFIG_DIR = "/home/locotoki/projects/alfred-agent-platform-v2/monitoring/prometheus"
PROMETHEUS_CONFIG_FILE = os.path.join(PROMETHEUS_CONFIG_DIR, "prometheus.yml")

# Service categories and names from docker-compose-clean.yml
SERVICE_CATEGORIES = {
    "infrastructure": ["redis", "vector-db", "pubsub-emulator", "llm-service"],
    "database": ["db-postgres", "db-auth", "db-api", "db-admin", "db-realtime", "db-storage"],
    "llm": ["model-registry", "model-router"],
    "agents": ["agent-core", "agent-rag", "agent-atlas", "agent-social", "agent-financial", "agent-legal"],
    "ui": ["ui-chat", "ui-admin", "auth-ui"],
    "monitoring": ["monitoring-metrics", "monitoring-dashboard", "monitoring-node", "monitoring-db", "monitoring-redis"],
    "mail": ["mail-server"]
}

def ensure_directory_exists(directory):
    """Ensure the specified directory exists."""
    if not os.path.exists(directory):
        os.makedirs(directory)
        print(f"Created directory: {directory}")

def load_existing_config():
    """Load the existing Prometheus configuration if it exists."""
    if os.path.exists(PROMETHEUS_CONFIG_FILE):
        with open(PROMETHEUS_CONFIG_FILE, 'r') as f:
            try:
                return yaml.safe_load(f)
            except yaml.YAMLError as e:
                print(f"Error parsing existing Prometheus config: {e}")
                return None
    return None

def create_default_config():
    """Create a default Prometheus configuration with essential settings."""
    return {
        "global": {
            "scrape_interval": "15s",
            "evaluation_interval": "15s",
            "scrape_timeout": "10s"
        },
        "alerting": {
            "alertmanagers": [{
                "static_configs": [{
                    "targets": []
                }]
            }]
        },
        "rule_files": [],
        "scrape_configs": []
    }

def add_container_discovery(config):
    """Add Docker container discovery to the Prometheus configuration."""
    if "scrape_configs" not in config:
        config["scrape_configs"] = []
    
    # Add a job for Docker container discovery
    docker_sd_job = {
        "job_name": "docker",
        "docker_sd_configs": [{
            "host": "unix:///var/run/docker.sock",
            "filters": [
                {"name": "label", "values": ["com.docker.compose.project=alfred"]}
            ]
        }],
        "relabel_configs": [
            # Extract container name for instance label
            {
                "source_labels": ["__meta_docker_container_name"],
                "regex": "/(.*)",
                "target_label": "instance"
            },
            # Extract service label
            {
                "source_labels": ["__meta_docker_container_label_com_docker_compose_service"],
                "target_label": "service"
            },
            # Extract group label
            {
                "source_labels": ["__meta_docker_container_label_com_docker_compose_group"],
                "target_label": "group"
            }
        ]
    }
    
    # Check if the job already exists
    for job in config["scrape_configs"]:
        if job.get("job_name") == "docker":
            print("Docker container discovery job already exists in the configuration")
            return config
    
    # Add the job if it doesn't exist
    config["scrape_configs"].append(docker_sd_job)
    print("Added Docker container discovery job to Prometheus configuration")
    
    return config

def add_service_health_checks(config):
    """Add health check jobs for each service category."""
    if "scrape_configs" not in config:
        config["scrape_configs"] = []
    
    # Add a job for each service category
    for category, services in SERVICE_CATEGORIES.items():
        job_name = f"{category}_health"
        
        # Check if the job already exists
        job_exists = False
        for job in config["scrape_configs"]:
            if job.get("job_name") == job_name:
                job_exists = True
                break
        
        if job_exists:
            print(f"Health check job for {category} already exists in the configuration")
            continue
        
        # Create a new job for this category
        health_job = {
            "job_name": job_name,
            "metrics_path": "/metrics",
            "docker_sd_configs": [{
                "host": "unix:///var/run/docker.sock",
                "filters": [
                    {"name": "label", "values": [f"com.docker.compose.group={category}"]}
                ]
            }],
            "relabel_configs": [
                # Extract container name for instance label
                {
                    "source_labels": ["__meta_docker_container_name"],
                    "regex": "/(.*)",
                    "target_label": "instance"
                },
                # Extract service name
                {
                    "source_labels": ["__meta_docker_container_label_com_docker_compose_service"],
                    "target_label": "service"
                }
            ]
        }
        
        config["scrape_configs"].append(health_job)
        print(f"Added health check job for {category} services")
    
    return config

def add_cadvisor_health_checks(config):
    """Add cAdvisor for container health metrics."""
    if "scrape_configs" not in config:
        config["scrape_configs"] = []
    
    # Check if the job already exists
    for job in config["scrape_configs"]:
        if job.get("job_name") == "cadvisor":
            print("cAdvisor job already exists in the configuration")
            return config
    
    # Add cAdvisor job
    cadvisor_job = {
        "job_name": "cadvisor",
        "scrape_interval": "15s",
        "scrape_timeout": "10s",
        "metrics_path": "/metrics",
        "static_configs": [{
            "targets": ["cadvisor:8080"]
        }]
    }
    
    config["scrape_configs"].append(cadvisor_job)
    print("Added cAdvisor job to Prometheus configuration")
    
    return config

def add_health_check_rules(config):
    """Add alerting rules for health checks."""
    rules_dir = os.path.join(PROMETHEUS_CONFIG_DIR, "rules")
    rules_file = os.path.join(rules_dir, "health_alerts.yml")
    
    # Ensure rules directory exists
    ensure_directory_exists(rules_dir)
    
    # Create health check rules
    health_rules = {
        "groups": [{
            "name": "health_alerts",
            "rules": [
                {
                    "alert": "ServiceDown",
                    "expr": "up == 0",
                    "for": "1m",
                    "labels": {
                        "severity": "critical"
                    },
                    "annotations": {
                        "summary": "Service {{ $labels.instance }} is down",
                        "description": "Service {{ $labels.instance }} has been down for more than 1 minute."
                    }
                },
                {
                    "alert": "HighServiceRestarts",
                    "expr": "changes(container_start_time_seconds[1h]) > 2",
                    "for": "5m",
                    "labels": {
                        "severity": "warning"
                    },
                    "annotations": {
                        "summary": "Service {{ $labels.instance }} has restarted multiple times",
                        "description": "Service {{ $labels.instance }} has restarted {{ $value }} times in the last hour."
                    }
                }
            ]
        }]
    }
    
    # Write rules to file
    with open(rules_file, 'w') as f:
        yaml.dump(health_rules, f, default_flow_style=False)
    
    print(f"Created health check rules in {rules_file}")
    
    # Add rule file to Prometheus config if not already there
    if "rule_files" not in config:
        config["rule_files"] = []
    
    rule_path = f"rules/health_alerts.yml"
    if rule_path not in config["rule_files"]:
        config["rule_files"].append(rule_path)
        print("Added health check rules to Prometheus configuration")
    
    return config

def write_config(config):
    """Write the Prometheus configuration to file."""
    with open(PROMETHEUS_CONFIG_FILE, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)
    
    print(f"Prometheus configuration written to {PROMETHEUS_CONFIG_FILE}")

def main():
    """Main function to set up Prometheus configuration."""
    print("Setting up Prometheus configuration for health checks...")
    
    # Ensure the Prometheus config directory exists
    ensure_directory_exists(PROMETHEUS_CONFIG_DIR)
    
    # Load existing config or create a new one
    config = load_existing_config()
    if config is None:
        config = create_default_config()
        print("Created new Prometheus configuration")
    
    # Add Docker container discovery
    config = add_container_discovery(config)
    
    # Add service health checks
    config = add_service_health_checks(config)
    
    # Add cAdvisor health checks
    config = add_cadvisor_health_checks(config)
    
    # Add health check rules
    config = add_health_check_rules(config)
    
    # Write the configuration to file
    write_config(config)
    
    print("\nPrometheus configuration for health checks has been set up successfully.")
    print(f"Configuration file: {PROMETHEUS_CONFIG_FILE}")
    print("To activate the configuration, restart the Prometheus service:")
    print("  docker-compose restart monitoring-metrics")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())