"""Protocol interfaces for alfred.remediation module.

This module defines the abstract interfaces used throughout the alfred.remediation
subsystem for automated service recovery and remediation workflows.
"""

from typing import Protocol, Dict, Any, List, Optional, Callable
from abc import abstractmethod
from enum import Enum


class RemediationState(Protocol):
    """Protocol for remediation workflow state."""
    
    @abstractmethod
    def get_service_name(self) -> str:
        """Get the name of the service being remediated.
        
        Returns:
            Service name.
        """
        ...
    
    @abstractmethod
    def get_status(self) -> str:
        """Get current remediation status.
        
        Returns:
            Status string.
        """
        ...
    
    @abstractmethod
    def set_result(self, result: Dict[str, Any]) -> None:
        """Set remediation result.
        
        Args:
            result: Result dictionary.
        """
        ...


class ServiceRemediation(Protocol):
    """Protocol for service remediation actions."""
    
    @abstractmethod
    async def restart_service(self, service_name: str) -> bool:
        """Restart a service.
        
        Args:
            service_name: Name of the service to restart.
            
        Returns:
            True if restart was successful.
        """
        ...
    
    @abstractmethod
    async def check_health(self, service_name: str) -> Dict[str, Any]:
        """Check service health status.
        
        Args:
            service_name: Name of the service.
            
        Returns:
            Health status dictionary.
        """
        ...
    
    @abstractmethod
    async def scale_service(self, service_name: str, replicas: int) -> bool:
        """Scale a service to specified replicas.
        
        Args:
            service_name: Name of the service.
            replicas: Desired number of replicas.
            
        Returns:
            True if scaling was successful.
        """
        ...


class WorkflowOrchestrator(Protocol):
    """Protocol for remediation workflow orchestration."""
    
    @abstractmethod
    def create_workflow(self, workflow_type: str, config: Dict[str, Any]) -> str:
        """Create a new remediation workflow.
        
        Args:
            workflow_type: Type of workflow to create.
            config: Workflow configuration.
            
        Returns:
            Workflow ID.
        """
        ...
    
    @abstractmethod
    async def execute_workflow(self, workflow_id: str, input_state: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a remediation workflow.
        
        Args:
            workflow_id: ID of the workflow to execute.
            input_state: Initial state for the workflow.
            
        Returns:
            Final state after workflow execution.
        """
        ...
    
    @abstractmethod
    def get_workflow_status(self, workflow_id: str) -> Dict[str, Any]:
        """Get status of a running workflow.
        
        Args:
            workflow_id: Workflow ID.
            
        Returns:
            Status dictionary.
        """
        ...


class AlertHandler(Protocol):
    """Protocol for handling alerts and triggering remediation."""
    
    @abstractmethod
    def process_alert(self, alert: Dict[str, Any]) -> Optional[str]:
        """Process an incoming alert and determine remediation action.
        
        Args:
            alert: Alert payload.
            
        Returns:
            Remediation action ID if action is needed, None otherwise.
        """
        ...
    
    @abstractmethod
    def get_remediation_history(self, service_name: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get remediation history for a service.
        
        Args:
            service_name: Name of the service.
            limit: Maximum number of records to return.
            
        Returns:
            List of remediation history records.
        """
        ...


class EscalationPolicy(Protocol):
    """Protocol for escalation policies."""
    
    @abstractmethod
    def should_escalate(self, service_name: str, failure_count: int, time_window: int) -> bool:
        """Determine if issue should be escalated.
        
        Args:
            service_name: Name of the service.
            failure_count: Number of failures.
            time_window: Time window in seconds.
            
        Returns:
            True if escalation is needed.
        """
        ...
    
    @abstractmethod
    def get_escalation_target(self, service_name: str, level: int) -> str:
        """Get escalation target for a given level.
        
        Args:
            service_name: Name of the service.
            level: Escalation level.
            
        Returns:
            Escalation target (e.g., email, slack channel).
        """
        ...