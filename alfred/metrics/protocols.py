"""Protocol interfaces for alfred.metrics module.

This module defines the abstract interfaces used throughout the alfred.metrics subsystem
for metrics collection, monitoring, and observability.
"""

from abc import abstractmethodLFfrom typing import Any, Dict, List, Optional, ProtocolLFLFfrom prometheus_client import CollectorRegistryLFLFLFclass MetricsCollector(Protocol):LF    """Protocol for metrics collection"""

    @abstractmethod
    def collect_metrics(self) -> Dict[str, float]:
        """Collect current metrics.

        Returns:
            Dictionary mapping metric names to their current values.
        """
        ...

    @abstractmethod
    def register_metric(
        self,
        name: str,
        metric_type: str,
        description: str,
        labels: Optional[List[str]] = None,
    ) -> None:
        """Register a new metric.

        Args:
            name: Metric name.
            metric_type: Type of metric (counter, gauge, histogram).
            description: Human-readable description.
            labels: Optional list of label names.
        """
        ...


class ServiceMonitor(Protocol):
    """Protocol for monitoring service health"""

    @abstractmethod
    def check_service_health(self, service_name: str, service_url: str) -> bool:
        """Check if a service is healthy.

        Args:
            service_name: Name of the service.
            service_url: URL endpoint to check.

        Returns:
            True if service is healthy, False otherwise.
        """
        ...

    @abstractmethod
    def get_service_metrics(self, service_name: str) -> Dict[str, Any]:
        """Get metrics for a specific service.

        Args:
            service_name: Name of the service.

        Returns:
            Dictionary containing service metrics.
        """
        ...


class PrometheusExporter(Protocol):
    """Protocol for Prometheus metrics export"""

    @abstractmethod
    def export_metrics(self) -> str:
        """Export metrics in Prometheus format.

        Returns:
            String containing metrics in Prometheus exposition format.
        """
        ...

    @abstractmethod
    def get_registry(self) -> CollectorRegistry:
        """Get the Prometheus collector registry.

        Returns:
            The CollectorRegistry instance.
        """
        ...


class DatabaseMetricsCollector(Protocol):
    """Protocol for database-specific metrics collection"""

    @abstractmethod
    def collect_connection_metrics(self) -> Dict[str, int]:
        """Collect database connection metrics.

        Returns:
            Dictionary with connection counts by state.
        """
        ...

    @abstractmethod
    def collect_query_metrics(self) -> Dict[str, float]:
        """Collect database query performance metrics.

        Returns:
            Dictionary with query performance statistics.
        """
        ...
