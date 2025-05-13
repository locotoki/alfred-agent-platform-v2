#!/usr/bin/env python3
"""
Script to seed a health check dashboard in Grafana.
This script creates a dashboard that displays the health status of all services.
"""
import json
import os
import requests
import sys
import time

# Configuration
GRAFANA_URL = os.environ.get("GRAFANA_URL", "http://localhost:3005")
GRAFANA_USER = os.environ.get("GRAFANA_USER", "admin")
GRAFANA_PASSWORD = os.environ.get("GRAFANA_PASSWORD", "admin")
PROMETHEUS_URL = os.environ.get("PROMETHEUS_URL", "http://localhost:9090")

# Service categories
SERVICE_CATEGORIES = {
    "Infrastructure": ["redis", "vector-db", "pubsub-emulator", "llm-service"],
    "Database": ["db-postgres", "db-auth", "db-api", "db-admin", "db-realtime", "db-storage"],
    "LLM": ["model-registry", "model-router"],
    "Agents": ["agent-core", "agent-rag", "agent-atlas", "agent-social", "agent-financial", "agent-legal"],
    "UI": ["ui-chat", "ui-admin", "auth-ui"],
    "Monitoring": ["monitoring-metrics", "monitoring-dashboard", "monitoring-node", "monitoring-db", "monitoring-redis"],
    "Mail": ["mail-server"]
}

# Flatten service list
ALL_SERVICES = [service for category in SERVICE_CATEGORIES.values() for service in category]

def create_api_session():
    """Create a session for Grafana API calls with proper authentication."""
    session = requests.Session()
    session.auth = (GRAFANA_USER, GRAFANA_PASSWORD)
    session.headers.update({
        "Content-Type": "application/json",
        "Accept": "application/json"
    })
    return session

def check_grafana_health(session):
    """Check if Grafana is healthy and ready for API calls."""
    try:
        response = session.get(f"{GRAFANA_URL}/api/health")
        response.raise_for_status()
        return response.json().get("database") == "ok"
    except Exception as e:
        print(f"Error checking Grafana health: {e}")
        return False

def wait_for_grafana(session, max_retries=30, retry_interval=5):
    """Wait for Grafana to be healthy before proceeding."""
    print("Checking Grafana health...")
    for attempt in range(max_retries):
        if check_grafana_health(session):
            print("Grafana is healthy!")
            return True
        print(f"Grafana not ready. Retrying in {retry_interval} seconds... ({attempt+1}/{max_retries})")
        time.sleep(retry_interval)
    
    print("Failed to connect to Grafana after maximum retries.")
    return False

def create_folder(session, folder_name):
    """Create a folder in Grafana for organizing dashboards."""
    try:
        # Check if folder exists first
        response = session.get(f"{GRAFANA_URL}/api/folders")
        response.raise_for_status()
        
        folders = response.json()
        for folder in folders:
            if folder["title"] == folder_name:
                print(f"Folder '{folder_name}' already exists with ID {folder['id']}")
                return folder["id"]
        
        # Create the folder if it doesn't exist
        payload = {
            "title": folder_name
        }
        response = session.post(f"{GRAFANA_URL}/api/folders", json=payload)
        response.raise_for_status()
        
        folder_id = response.json()["id"]
        print(f"Created folder '{folder_name}' with ID {folder_id}")
        return folder_id
    
    except Exception as e:
        print(f"Error creating folder: {e}")
        return None

def create_health_dashboard(session, folder_id):
    """Create a health check dashboard in Grafana."""
    
    # Generate panels for each service category
    panels = []
    panel_y_pos = 0
    
    # Add title panel
    panels.append({
        "id": 1,
        "gridPos": {"h": 3, "w": 24, "x": 0, "y": panel_y_pos},
        "type": "text",
        "title": "Service Health Status",
        "options": {
            "mode": "markdown",
            "content": "# Alfred Agent Platform Service Health\nThis dashboard shows the health status of all services in the platform. Green means healthy, red means unhealthy, and grey means not monitored."
        }
    })
    panel_y_pos += 3
    
    # Add refresh time panel
    panels.append({
        "id": 2,
        "gridPos": {"h": 3, "w": 24, "x": 0, "y": panel_y_pos},
        "type": "text",
        "title": "Last Refresh",
        "options": {
            "mode": "markdown",
            "content": "Dashboard last refreshed at: ${__now:time:YYYY-MM-DD HH:mm:ss}"
        }
    })
    panel_y_pos += 3
    
    panel_id = 3
    
    # Add category panels
    for category, services in SERVICE_CATEGORIES.items():
        # Add category header
        panels.append({
            "id": panel_id,
            "gridPos": {"h": 2, "w": 24, "x": 0, "y": panel_y_pos},
            "type": "text",
            "title": "",
            "options": {
                "mode": "markdown",
                "content": f"## {category} Services"
            }
        })
        panel_id += 1
        panel_y_pos += 2
        
        # Add status panels for each service in the category
        service_panels_per_row = 6
        panel_width = 24 // service_panels_per_row
        
        for i, service in enumerate(services):
            x_pos = (i % service_panels_per_row) * panel_width
            if i > 0 and i % service_panels_per_row == 0:
                panel_y_pos += 5
            
            # Common health check pattern for container health
            expr = f'up{{instance=~".*{service}.*"}} == 1'
            
            panels.append({
                "id": panel_id,
                "gridPos": {"h": 5, "w": panel_width, "x": x_pos, "y": panel_y_pos},
                "type": "stat",
                "title": service,
                "targets": [
                    {
                        "expr": expr,
                        "refId": "A"
                    }
                ],
                "options": {
                    "colorMode": "value",
                    "graphMode": "area",
                    "justifyMode": "auto",
                    "orientation": "auto",
                    "reduceOptions": {
                        "calcs": ["lastNotNull"],
                        "fields": "",
                        "values": False
                    },
                    "textMode": "auto"
                },
                "fieldConfig": {
                    "defaults": {
                        "mappings": [
                            {
                                "options": {
                                    "0": {
                                        "color": "red",
                                        "index": 0,
                                        "text": "Down"
                                    },
                                    "1": {
                                        "color": "green",
                                        "index": 1,
                                        "text": "Up"
                                    }
                                },
                                "type": "value"
                            }
                        ],
                        "thresholds": {
                            "mode": "absolute",
                            "steps": [
                                {
                                    "color": "red",
                                    "value": 0
                                },
                                {
                                    "color": "green",
                                    "value": 1
                                }
                            ]
                        },
                        "color": {
                            "mode": "thresholds"
                        },
                        "unit": "none"
                    }
                }
            })
            panel_id += 1
        
        panel_y_pos += 5
    
    # Create the dashboard JSON
    dashboard = {
        "dashboard": {
            "id": None,
            "uid": "alfred-health-status",
            "title": "Alfred Platform Health Status",
            "tags": ["health", "status", "alfred"],
            "timezone": "browser",
            "schemaVersion": 30,
            "version": 1,
            "refresh": "10s",
            "panels": panels
        },
        "folderId": folder_id,
        "overwrite": True
    }
    
    # Create the dashboard in Grafana
    try:
        response = session.post(f"{GRAFANA_URL}/api/dashboards/db", json=dashboard)
        response.raise_for_status()
        
        dashboard_url = f"{GRAFANA_URL}{response.json()['url']}"
        print(f"Created health dashboard at: {dashboard_url}")
        return dashboard_url
    
    except Exception as e:
        print(f"Error creating dashboard: {e}")
        return None

def create_health_metrics_dashboard(session, folder_id):
    """Create a dashboard for detailed health metrics."""
    
    # Build panels for health metrics dashboard
    panels = []
    panel_y_pos = 0
    
    # Add title panel
    panels.append({
        "id": 1,
        "gridPos": {"h": 3, "w": 24, "x": 0, "y": panel_y_pos},
        "type": "text",
        "title": "Health Metrics Dashboard",
        "options": {
            "mode": "markdown",
            "content": "# Health Metrics Dashboard\nDetailed metrics for service health, performance, and availability."
        }
    })
    panel_y_pos += 3
    
    # Service uptime panel
    panels.append({
        "id": 2,
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": panel_y_pos},
        "type": "timeseries",
        "title": "Service Uptime",
        "targets": [
            {
                "expr": "sum(up) / count(up)",
                "refId": "A",
                "legendFormat": "Uptime Ratio"
            }
        ],
        "options": {
            "legend": {"showLegend": True},
            "tooltip": {"mode": "single", "sort": "none"}
        },
        "fieldConfig": {
            "defaults": {
                "color": {"mode": "palette-classic"},
                "custom": {
                    "axisCenteredZero": False,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 20,
                    "gradientMode": "none",
                    "hideFrom": {"legend": False, "tooltip": False, "viz": False},
                    "lineInterpolation": "smooth",
                    "lineWidth": 2,
                    "pointSize": 5,
                    "scaleDistribution": {"type": "linear"},
                    "showPoints": "never",
                    "spanNulls": True,
                    "stacking": {"group": "A", "mode": "none"},
                    "thresholdsStyle": {"mode": "off"}
                },
                "mappings": [],
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                        {"color": "red", "value": 0},
                        {"color": "orange", "value": 0.7},
                        {"color": "green", "value": 0.9}
                    ]
                },
                "unit": "percentunit"
            }
        }
    })
    
    # Service count panel
    panels.append({
        "id": 3,
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": panel_y_pos},
        "type": "stat",
        "title": "Service Status Count",
        "targets": [
            {
                "expr": "sum(up == 1)",
                "refId": "A",
                "legendFormat": "Healthy"
            },
            {
                "expr": "sum(up == 0)",
                "refId": "B",
                "legendFormat": "Unhealthy"
            }
        ],
        "options": {
            "colorMode": "value",
            "graphMode": "area",
            "justifyMode": "auto",
            "orientation": "horizontal",
            "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": True
            },
            "textMode": "auto"
        },
        "fieldConfig": {
            "defaults": {
                "mappings": [],
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                        {"color": "green", "value": 0}
                    ]
                },
                "color": {"mode": "thresholds"},
                "unit": "none"
            },
            "overrides": [
                {
                    "matcher": {"id": "byName", "options": "Healthy"},
                    "properties": [
                        {"id": "color", "value": {"mode": "fixed", "fixedColor": "green"}}
                    ]
                },
                {
                    "matcher": {"id": "byName", "options": "Unhealthy"},
                    "properties": [
                        {"id": "color", "value": {"mode": "fixed", "fixedColor": "red"}}
                    ]
                }
            ]
        }
    })
    
    panel_y_pos += 8
    
    # Service category health status
    panels.append({
        "id": 4,
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": panel_y_pos},
        "type": "gauge",
        "title": "Service Category Health",
        "targets": [
            {
                "expr": f'sum(up{{job=~"{category.lower()}.*"}}) / count(up{{job=~"{category.lower()}.*"}})',
                "refId": chr(65 + i),
                "legendFormat": category
            } for i, category in enumerate(SERVICE_CATEGORIES.keys())
        ],
        "options": {
            "orientation": "horizontal",
            "reduceOptions": {
                "calcs": ["lastNotNull"],
                "fields": "",
                "values": False
            },
            "showThresholdLabels": False,
            "showThresholdMarkers": True
        },
        "fieldConfig": {
            "defaults": {
                "mappings": [],
                "thresholds": {
                    "mode": "percentage",
                    "steps": [
                        {"color": "red", "value": 0},
                        {"color": "orange", "value": 50},
                        {"color": "green", "value": 80}
                    ]
                },
                "color": {"mode": "thresholds"},
                "unit": "percentunit"
            }
        }
    })
    
    panel_y_pos += 8
    
    # Create the dashboard JSON
    dashboard = {
        "dashboard": {
            "id": None,
            "uid": "alfred-health-metrics",
            "title": "Alfred Platform Health Metrics",
            "tags": ["health", "metrics", "alfred"],
            "timezone": "browser",
            "schemaVersion": 30,
            "version": 1,
            "refresh": "10s",
            "panels": panels
        },
        "folderId": folder_id,
        "overwrite": True
    }
    
    # Create the dashboard in Grafana
    try:
        response = session.post(f"{GRAFANA_URL}/api/dashboards/db", json=dashboard)
        response.raise_for_status()
        
        dashboard_url = f"{GRAFANA_URL}{response.json()['url']}"
        print(f"Created health metrics dashboard at: {dashboard_url}")
        return dashboard_url
    
    except Exception as e:
        print(f"Error creating metrics dashboard: {e}")
        return None

def main():
    """Main function to seed Grafana dashboards."""
    print("Starting Grafana dashboard seeding...")
    
    # Create a session for API calls
    session = create_api_session()
    
    # Wait for Grafana to be up and running
    if not wait_for_grafana(session):
        sys.exit(1)
    
    # Create a folder for the dashboards
    folder_id = create_folder(session, "Alfred Platform")
    if folder_id is None:
        sys.exit(1)
    
    # Create the health dashboard
    health_dashboard_url = create_health_dashboard(session, folder_id)
    if health_dashboard_url is None:
        sys.exit(1)
    
    # Create the health metrics dashboard
    metrics_dashboard_url = create_health_metrics_dashboard(session, folder_id)
    if metrics_dashboard_url is None:
        sys.exit(1)
    
    print("\nDashboard seeding completed successfully!")
    print(f"Health Dashboard URL: {health_dashboard_url}")
    print(f"Health Metrics Dashboard URL: {metrics_dashboard_url}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())