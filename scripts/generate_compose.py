#!/usr/bin/env python3
"""Generate docker-compose.yml from individual service compose snippets."""
from pathlib import Path
from typing import Any, Dict, List

import yaml


def load_services() -> Dict[str, List[str]]:
    """Load the canonical services list."""
    with open("services.yaml", "r") as f:
        services_data = yaml.safe_load(f)

    # Maintain grouped structure for profile assignment
    return services_data  # type: ignore


def merge_compose_files(services_data: Dict[str, List[str]]) -> Dict[str, Any]:
    """Merge all service compose snippets into a single compose file."""
    final_compose: Dict[str, Any] = {
        "version": "3.8",
        "services": {},
        "networks": {"alfred-network": {"driver": "bridge"}},
        "volumes": {},
    }

    services_dir = Path("services")
    adapters_dir = Path("adapters")

    # Process each service group
    for category, service_list in services_data.items():
        for service_name in service_list:
            # Check in services directory first
            compose_file = services_dir / service_name / "compose.yml"

            # If not found, check in adapters directory
            if not compose_file.exists():
                compose_file = adapters_dir / service_name / "compose.yml"

            if compose_file.exists():
                try:
                    with open(compose_file, "r") as f:
                        service_compose = yaml.safe_load(f)

                    if "services" in service_compose:
                        # Merge service definition
                        for svc_name, svc_config in service_compose["services"].items():
                            # Add profile based on category
                            if category == "core":
                                svc_config["profiles"] = ["core", "full"]
                            elif category == "monitoring":
                                svc_config["profiles"] = ["monitoring", "full"]
                            else:
                                svc_config["profiles"] = [category, "full"]

                            final_compose["services"][svc_name] = svc_config

                    # Merge volumes if defined
                    if "volumes" in service_compose:
                        final_compose["volumes"].update(service_compose["volumes"])

                except Exception as e:
                    print(f"Error reading {compose_file}: {e}")
            else:
                print(f"Warning: No compose.yml found for {service_name}")

    # Add environment configuration directly to services
    for service_name in final_compose["services"]:
        if "environment" not in final_compose["services"][service_name]:
            final_compose["services"][service_name]["environment"] = []

        # Add standard environment variables
        if isinstance(final_compose["services"][service_name]["environment"], list):
            env_vars = final_compose["services"][service_name]["environment"]
            if not any(env.startswith("ALFRED_ENVIRONMENT=") for env in env_vars):
                env_vars.append("ALFRED_ENVIRONMENT=${ALFRED_ENVIRONMENT}")
            if not any(env.startswith("ALFRED_LOG_LEVEL=") for env in env_vars):
                env_vars.append("ALFRED_LOG_LEVEL=${ALFRED_LOG_LEVEL}")
        elif isinstance(final_compose["services"][service_name]["environment"], dict):
            env_dict = final_compose["services"][service_name]["environment"]
            if "ALFRED_ENVIRONMENT" not in env_dict:
                env_dict["ALFRED_ENVIRONMENT"] = "${ALFRED_ENVIRONMENT}"
            if "ALFRED_LOG_LEVEL" not in env_dict:
                env_dict["ALFRED_LOG_LEVEL"] = "${ALFRED_LOG_LEVEL}"

    return final_compose


def write_compose_file(compose_data: Dict[str, Any], output_file: str) -> None:
    """Write the generated compose file."""
    with open(output_file, "w") as f:
        yaml.dump(compose_data, f, default_flow_style=False, sort_keys=False)
    print(f"Generated: {output_file}")


def main() -> None:
    """Generate the complete docker-compose file."""
    services_data = load_services()
    compose_data = merge_compose_files(services_data)

    output_file = "docker-compose.generated.yml"
    write_compose_file(compose_data, output_file)

    # Summary
    print("\nSummary:")
    print(f"Total services: {len(compose_data['services'])}")
    print(
        f"Profiles: {set(svc.get('profiles', [])[0] for svc in compose_data['services'].values() if svc.get('profiles'))}"  # noqa: E501
    )


if __name__ == "__main__":
    main()
