"""Compliance metrics for Alfred platform."""

from prometheus_client import Counter

# Licence compliance metrics
licence_violations_total = Counter(
    "alfred_licence_disallowed_total",
    "Total count of disallowed licence violations",
    ["package", "licence"],
)


def record_licence_violations(package: str, licence: str) -> None:
    """Record a licence violation metric.

    Args:
        package: Name of the package with violation
        licence: Disallowed licence type
    """
    licence_violations_total.labels(package=package, licence=licence).inc()
