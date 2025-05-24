"""Enhanced Prometheus metrics for the Social Intelligence service"""

# type: ignore
import timeLFLFfrom prometheus_client import Counter, Gauge, Histogram, SummaryLFLF# Request metricsLFSI_REQUESTS_TOTAL = Counter(LF    "si_requests_total",
    "Total number of requests to the Social Intelligence API",
    ["endpoint", "status"],
)

# Latency metrics (in seconds)
SI_LATENCY_SECONDS = Histogram(
    "si_latency_seconds",
    "Request latency in seconds",
    ["endpoint"],
    buckets=[0.05, 0.1, 0.2, 0.4, 0.8, 2],
)

# Worker lag metrics (in seconds)
WORKER_LAG_SECONDS = Gauge("si_worker_lag_seconds", "Lag time for workers in seconds")

# Database metrics
DB_QUERY_SECONDS = Histogram(
    "si_db_query_seconds",
    "Database query time in seconds",
    ["operation"],
    buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)

# Database errors metric (NEW)
DB_ERROR_COUNTER = Counter(
    "si_db_errors_total", "Total number of database errors", ["type", "operation"]
)

# Social Intel specific metrics
NICHE_SCOUT_RESULTS_COUNT = Gauge("si_niche_scout_results", "Number of niche results returned")

NICHE_OPPORTUNITY_SCORE = Histogram(
    "si_niche_opportunity_score",
    "Distribution of niche opportunity scores",
    buckets=[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.5, 2.0, 5.0],
)

# Offline mode tracking (NEW)
OFFLINE_MODE_GAUGE = Gauge(
    "si_offline_mode", "Whether the service is in offline mode (1) or online mode (0)"
)

# YouTube API metrics (NEW)
YOUTUBE_API_CALLS = Counter(
    "si_youtube_api_calls_total",
    "Total number of YouTube API calls",
    ["endpoint", "status"],
)

YOUTUBE_API_LATENCY = Summary(
    "si_youtube_api_latency_seconds",
    "YouTube API call latency in seconds",
    ["endpoint"],
)

# Circuit breaker metrics (NEW)
CIRCUIT_STATE = Gauge(
    "si_circuit_state",
    "Circuit breaker state (0=closed, 1=half-open, 2=open)",
    ["circuit"],
)

CIRCUIT_REJECTED = Counter(
    "si_circuit_rejected_total",
    "Number of requests rejected by circuit breakers",
    ["circuit"],
)


class LatencyTimer:
    """Context manager for timing operations and recording metrics"""

    def __init__(self, metric, labels=None):
        self.metric = metric
        self.labels = labels or {}
        self.start_time = None

    def __enter__(self):
        self.start_time = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        if isinstance(self.metric, Histogram):
            self.metric.labels(**self.labels).observe(duration)
        elif isinstance(self.metric, Gauge):
            self.metric.labels(**self.labels).set(duration)
        elif isinstance(self.metric, Summary):
            self.metric.labels(**self.labels).observe(duration)
        return False  # Don't suppress exceptions


class YouTubeApiTimer(LatencyTimer):
    """Specialized timer for YouTube API calls that also counts requests"""

    def __init__(self, endpoint, status="success"):
        super().__init__(YOUTUBE_API_LATENCY, {"endpoint": endpoint})
        self.endpoint = endpoint
        self.status = status

    def __enter__(self):
        YOUTUBE_API_CALLS.labels(endpoint=self.endpoint, status="pending").inc()
        return super().__enter__()

    def __exit__(self, exc_type, exc_val, exc_tb):
        result = super().__exit__(exc_type, exc_val, exc_tb)

        # Update status based on exception
        status = self.status
        if exc_type is not None:
            status = "error"

        # Increment counter with final status
        YOUTUBE_API_CALLS.labels(endpoint=self.endpoint, status=status).inc()

        return result


class DatabaseTimer(LatencyTimer):
    """Specialized timer for database operations that also tracks errors"""

    def __init__(self, operation):
        super().__init__(DB_QUERY_SECONDS, {"operation": operation})
        self.operation = operation

    def __exit__(self, exc_type, exc_val, exc_tb):
        result = super().__exit__(exc_type, exc_val, exc_tb)

        # Record error if exception occurred
        if exc_type is not None:
            error_type = exc_type.__name__
            DB_ERROR_COUNTER.labels(type=error_type, operation=self.operation).inc()

        return result
