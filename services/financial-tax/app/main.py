"""Financial Tax Service FastAPI Application"""

from fastapi import FastAPI, HTTPException, Request, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
import structlog
import redis
from prometheus_client import Counter, Histogram, Gauge

from libs.a2a_adapter import A2AEnvelope, PubSubTransport, SupabaseTransport, PolicyMiddleware
from libs.agent_core.health import create_health_app
from agents.financial_tax import (
    FinancialTaxAgent,
    TaxCalculationRequest,
    FinancialAnalysisRequest,
    ComplianceCheckRequest,
    TaxRateRequest,
)

logger = structlog.get_logger(__name__)

# Initialize Prometheus metrics
TASK_COUNTER = Counter("financial_tax_tasks_total", "Total tasks processed", ["intent", "status"])

TASK_DURATION = Histogram(
    "financial_tax_task_duration_seconds", "Task processing duration", ["intent"]
)

API_REQUESTS = Counter(
    "financial_tax_api_requests_total", "Total API requests", ["endpoint", "method", "status"]
)

ACTIVE_TASKS = Gauge("financial_tax_active_tasks", "Currently processing tasks")

# Initialize services
pubsub_transport = PubSubTransport(project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform"))

supabase_transport = SupabaseTransport(database_url=os.getenv("DATABASE_URL"))

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
policy_middleware = PolicyMiddleware(redis_client)

# Initialize the agent
financial_tax_agent = FinancialTaxAgent(
    pubsub_transport=pubsub_transport,
    supabase_transport=supabase_transport,
    policy_middleware=policy_middleware,
)

# Security
security = HTTPBearer()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Startup
    await supabase_transport.connect()
    await financial_tax_agent.start()
    logger.info("financial_tax_service_started")

    yield

    # Shutdown
    await financial_tax_agent.stop()
    await supabase_transport.disconnect()
    logger.info("financial_tax_service_stopped")


app = FastAPI(
    title="Financial Tax Service",
    description="API for tax calculations, financial analysis, and compliance checking",
    version="1.0.0",
    lifespan=lifespan,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add health check endpoints
health_app = create_health_app("financial-tax", "1.0.0")
app.mount("/health", health_app)


# API Routes
@app.post("/api/v1/financial-tax/calculate-tax")
async def calculate_tax(
    request: TaxCalculationRequest, credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Calculate tax liability based on input data."""
    API_REQUESTS.labels(endpoint="calculate-tax", method="POST", status="processing").inc()

    try:
        # Create envelope for the task
        envelope = A2AEnvelope(intent="TAX_CALCULATION", content=request.dict())

        # Store task
        task_id = await supabase_transport.store_task(envelope)

        # Publish task
        message_id = await pubsub_transport.publish_task(envelope)

        API_REQUESTS.labels(endpoint="calculate-tax", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Tax calculation task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="calculate-tax", method="POST", status="error").inc()
        logger.error("tax_calculation_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/financial-tax/analyze-financials")
async def analyze_financials(
    request: FinancialAnalysisRequest,
    credentials: HTTPAuthorizationCredentials = Security(security),
):
    """Perform financial analysis on submitted data."""
    API_REQUESTS.labels(endpoint="analyze-financials", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(intent="FINANCIAL_ANALYSIS", content=request.dict())

        task_id = await supabase_transport.store_task(envelope)
        message_id = await pubsub_transport.publish_task(envelope)

        API_REQUESTS.labels(endpoint="analyze-financials", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Financial analysis task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="analyze-financials", method="POST", status="error").inc()
        logger.error("financial_analysis_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/financial-tax/check-compliance")
async def check_compliance(
    request: ComplianceCheckRequest, credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Check tax compliance for given transactions."""
    API_REQUESTS.labels(endpoint="check-compliance", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(intent="TAX_COMPLIANCE_CHECK", content=request.dict())

        task_id = await supabase_transport.store_task(envelope)
        message_id = await pubsub_transport.publish_task(envelope)

        API_REQUESTS.labels(endpoint="check-compliance", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Compliance check task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="check-compliance", method="POST", status="error").inc()
        logger.error("compliance_check_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/financial-tax/tax-rates/{jurisdiction}")
async def get_tax_rates(
    jurisdiction: str,
    tax_year: int = None,
    entity_type: str = None,
    credentials: HTTPAuthorizationCredentials = Security(security),
):
    """Retrieve tax rates for specified jurisdiction."""
    API_REQUESTS.labels(endpoint="tax-rates", method="GET", status="processing").inc()

    try:
        # Create request object
        rate_request = TaxRateRequest(
            jurisdiction=jurisdiction,
            tax_year=tax_year or 2024,
            entity_type=entity_type or "individual",
        )

        envelope = A2AEnvelope(intent="RATE_SHEET_LOOKUP", content=rate_request.dict())

        task_id = await supabase_transport.store_task(envelope)
        message_id = await pubsub_transport.publish_task(envelope)

        API_REQUESTS.labels(endpoint="tax-rates", method="GET", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Tax rate lookup task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="tax-rates", method="GET", status="error").inc()
        logger.error("tax_rate_lookup_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/financial-tax/task/{task_id}")
async def get_task_status(
    task_id: str, credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Get status of a specific task."""
    try:
        task_status = await supabase_transport.get_task_status(task_id)

        if not task_status:
            raise HTTPException(status_code=404, detail="Task not found")

        return task_status
    except HTTPException:
        raise
    except Exception as e:
        logger.error("task_status_api_error", error=str(e), task_id=task_id)
        raise HTTPException(status_code=500, detail=str(e))


# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Handle HTTP exceptions."""
    return {"error": exc.detail, "status_code": exc.status_code}


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions."""
    logger.error("unhandled_exception", error=str(exc))
    return {"error": "Internal server error", "status_code": 500}
