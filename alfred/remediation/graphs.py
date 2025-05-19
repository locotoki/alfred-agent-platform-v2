"""
Remediation graphs for automated service recovery.

This module provides LangGraph-based workflows for service remediation,
including restart, health verification, and escalation paths.
"""

import logging
import time
from typing import Any, Dict, Tuple

import requests
from langgraph.graph import END, StateGraph

from alfred.remediation import settings

logger = logging.getLogger(__name__)


class RemediationState(Dict[str, Any]):
    """Type definition for remediation graph state"""

    pass


def restart_service(state: RemediationState) -> RemediationState:
    """Restart a service using n8n workflow"""
    service_name = state.get("service_name")
    logger.info(f"Restarting service: {service_name}")

    try:
        # Get webhook URL for the service
        if service_name is None:
            raise ValueError("Service name is required for restart")
        webhook_url = settings.get_webhook_url(service_name)

        # Call n8n workflow to restart service
        response = requests.post(
            webhook_url, json={"service": service_name}, timeout=settings.PROBE_TIMEOUT
        )
        response.raise_for_status()
        state["restart_status"] = "success"
        state["restart_timestamp"] = time.time()
        logger.info(f"Service restart initiated: {service_name}")
    except Exception as e:
        logger.error(f"Failed to restart service: {e}")
        state["restart_status"] = "failed"
        state["error"] = str(e)

    return state


def wait_for_stabilization(state: RemediationState) -> RemediationState:
    """Wait for service to stabilize after restart"""
    wait_seconds = state.get("wait_seconds", settings.DEFAULT_WAIT_SECONDS)
    service_name = state.get("service_name")
    logger.info(f"Waiting {wait_seconds}s for {service_name} to stabilize")

    time.sleep(wait_seconds)
    state["wait_completed"] = True
    state["wait_timestamp"] = time.time()

    return state


def probe_health(state: RemediationState) -> RemediationState:
    """Probe service health after restart"""
    service_name = state.get("service_name")
    logger.info(f"Probing health for: {service_name}")

    try:
        # Call health probe endpoint
        response = requests.get(
            f"http://{service_name}:8080/health", timeout=settings.PROBE_TIMEOUT
        )
        state["probe_status_code"] = response.status_code
        state["probe_response"] = response.text
        state["health_ok"] = response.status_code == 200
        state["probe_timestamp"] = time.time()

        logger.info(f"Health probe result for {service_name}: status={response.status_code}")
    except Exception as e:
        logger.error(f"Failed to probe service health: {e}")
        state["probe_status_code"] = 500
        state["probe_response"] = str(e)
        state["health_ok"] = False
        state["probe_timestamp"] = time.time()
        state["probe_error"] = str(e)  # Expose exception details

    return state


def should_retry_or_complete(state: RemediationState) -> str:
    """Decision node to determine if we should retry restart or complete"""
    max_retries = state.get("max_retries", settings.MAX_RETRIES)
    current_retry = state.get("retry_count", 0)
    health_ok = state.get("health_ok", False)

    if health_ok:
        return "complete"

    if current_retry >= max_retries:
        return "escalate"

    # Increment retry counter
    state["retry_count"] = current_retry + 1
    return "retry"


def complete_remediation(state: RemediationState) -> RemediationState:
    """Complete remediation with success"""
    service_name = state.get("service_name")
    thread_ts = state.get("thread_ts")
    channel = state.get("channel")

    logger.info(f"Remediation completed successfully for {service_name}")

    if thread_ts and channel:
        # Would update Slack thread in real implementation
        state["thread_updated"] = True
        state["completion_message"] = f"Service {service_name} has been successfully remediated."

    state["remediation_status"] = "success"
    state["remediation_completed"] = True

    return state


def escalate_issue(state: RemediationState) -> RemediationState:
    """Escalate issue after max retries"""
    service_name = state.get("service_name")
    thread_ts = state.get("thread_ts")
    channel = state.get("channel")
    max_retries = state.get("max_retries", settings.MAX_RETRIES)

    logger.info(
        f"Escalating remediation for {service_name} "
        f"after {state.get('retry_count', 0)}/{max_retries} failed attempts"
    )

    # Build error details from probe_error if available
    error_details = ""
    if "probe_error" in state:
        error_details = f"\nLast error: {state['probe_error']}"

    if thread_ts and channel:
        # Would update Slack thread in real implementation
        state["thread_updated"] = True
        state["escalation_message"] = (
            f"❌ Failed to remediate {service_name} after "
            f"{state.get('retry_count', 0)}/{max_retries} attempts. "
            f"This issue has been escalated to the on-call team.{error_details}"
        )

    state["remediation_status"] = "escalated"
    state["remediation_completed"] = True

    return state


def restart_then_verify(
    service_name: str,
    wait_seconds: int = settings.DEFAULT_WAIT_SECONDS,
    max_retries: int = settings.MAX_RETRIES,
) -> Tuple[StateGraph, RemediationState]:
    """
    Creates a remediation graph that:
    1. Restarts the service
    2. Waits for it to stabilize
    3. Probes its health
    4. Either completes successfully, retries, or escalates

    Args:
        service_name: Name of the service to remediate
        wait_seconds: Time to wait for service stabilization
        max_retries: Maximum number of restart attempts

    Returns:
        Tuple of (StateGraph, initial_state): The configured remediation workflow
        and its initial state
    """
    # Create initial state
    initial_state = {
        "service_name": service_name,
        "wait_seconds": wait_seconds,
        "max_retries": max_retries,
        "retry_count": 0,
        "start_timestamp": time.time(),
    }

    # Create the graph
    workflow = StateGraph(RemediationState)

    # Add nodes
    workflow.add_node("restart", restart_service)
    workflow.add_node("wait", wait_for_stabilization)
    workflow.add_node("probe", probe_health)
    workflow.add_node("complete", complete_remediation)
    workflow.add_node("escalate", escalate_issue)

    # Add edges
    workflow.add_edge("restart", "wait")
    workflow.add_edge("wait", "probe")

    # Add conditional edges
    workflow.add_conditional_edges(
        "probe",
        should_retry_or_complete,
        {"complete": "complete", "escalate": "escalate", "retry": "restart"},
    )

    # End states
    workflow.add_edge("complete", END)
    workflow.add_edge("escalate", END)

    # Set the entry point
    workflow.set_entry_point("restart")

    return workflow.compile(), initial_state  # type: ignore[return-value]
