# isort: skip_file
"""Legal Compliance Service FastAPI Application"""

# type: ignore
import os
from contextlib import asynccontextmanager

import redis
import structlog
from fastapi import FastAPI, HTTPException, Request, Security
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from prometheus_client import Counter, Gauge, Histogram

from agents.legal_compliance import (
    ComplianceAuditRequest,
    ContractReviewRequest,
    DocumentAnalysisRequest,
    LegalComplianceAgent,
    RegulationCheckRequest,
)
from libs.a2a_adapter import A2AEnvelope, PolicyMiddleware, PubSubTransport, SupabaseTransport
from libs.agent_core.health import create_health_app

logger = structlog.get_logger(__name__)

# Initialize Prometheus metrics
TASK_COUNTER = Counter(
    "legal_compliance_tasks_total", "Total tasks processed", ["intent", "status"]
)

TASK_DURATION = Histogram(
    "legal_compliance_task_duration_seconds", "Task processing duration", ["intent"]
)

API_REQUESTS = Counter(
    "legal_compliance_api_requests_total",
    "Total API requests",
    ["endpoint", "method", "status"],
)

ACTIVE_TASKS = Gauge("legal_compliance_active_tasks", "Currently processing tasks")

# Initialize services
pubsub_transport = PubSubTransport(project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform"))

supabase_transport = SupabaseTransport(database_url=os.getenv("DATABASE_URL"))

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
policy_middleware = PolicyMiddleware(redis_client)

# Initialize the agent
legal_compliance_agent = LegalComplianceAgent(
    pubsub_transport=pubsub_transport,
    supabase_transport=supabase_transport,
    policy_middleware=policy_middleware,
)

# Security
security = HTTPBearer()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    # Startup
    await supabase_transportconnect()  # type: ignore[name-defined]
    await legal_compliance_agentstart()  # type: ignore[name-defined]
    logger.info("legal_compliance_service_started")

    yield

    # Shutdown
    await legal_compliance_agentstop()  # type: ignore[name-defined]
    await supabase_transportdisconnect()  # type: ignore[name-defined]
    logger.info("legal_compliance_service_stopped")


app = FastAPI(
    title="Legal Compliance Service",
    description="API for legal compliance audits, document analysis, and regulation checks",
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
health_app = create_health_app("legal-compliance", "1.0.0")
app.mount("/health", health_app)


# API Routes
@app.post("/api/v1/legal-compliance/audit-compliance")
async def audit_compliance(
    request: ComplianceAuditRequest,
    credentials: HTTPAuthorizationCredentials = Security(security),
):
    """Perform compliance audit on submitted documents and processes"""
    API_REQUESTS.labels(endpoint="audit-compliance", method="POST", status="processing").inc()

    try:
        # Create envelope for the task
        envelope = A2AEnvelope(intent="COMPLIANCE_AUDIT", content=request.dict())

        # Store task
        await supabase_transportstore_task(envelope)  # type: ignore[name-defined]

        # Publish task
        message_id = await pubsub_transportpublish_task(envelope)  # type: ignore[name-defined]

        API_REQUESTS.labels(endpoint="audit-compliance", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Compliance audit task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="audit-compliance", method="POST", status="error").inc()
        logger.error("compliance_audit_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/legal-compliance/analyze-document")
async def analyze_document(
    request: DocumentAnalysisRequest,
    credentials: HTTPAuthorizationCredentials = Security(security),
):
    """Analyze legal document for compliance issues"""
    API_REQUESTS.labels(endpoint="analyze-document", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(intent="DOCUMENT_ANALYSIS", content=request.dict())

        await supabase_transportstore_task(envelope)  # type: ignore[name-defined]
        message_id = await pubsub_transportpublish_task(envelope)  # type: ignore[name-defined]

        API_REQUESTS.labels(endpoint="analyze-document", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Document analysis task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="analyze-document", method="POST", status="error").inc()
        logger.error("document_analysis_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/legal-compliance/check-regulations")
async def check_regulations(
    request: RegulationCheckRequest,
    credentials: HTTPAuthorizationCredentials = Security(security),
):
    """Check compliance against specific regulations"""
    API_REQUESTS.labels(endpoint="check-regulations", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(intent="REGULATION_CHECK", content=request.dict())

        await supabase_transportstore_task(envelope)  # type: ignore[name-defined]
        message_id = await pubsub_transportpublish_task(envelope)  # type: ignore[name-defined]

        API_REQUESTS.labels(endpoint="check-regulations", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Regulation check task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="check-regulations", method="POST", status="error").inc()
        logger.error("regulation_check_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/legal-compliance/review-contract")
async def review_contract(
    request: ContractReviewRequest,
    credentials: HTTPAuthorizationCredentials = Security(security),
):
    """Review contract for legal compliance and potential issues"""
    API_REQUESTS.labels(endpoint="review-contract", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(intent="CONTRACT_REVIEW", content=request.dict())

        await supabase_transportstore_task(envelope)  # type: ignore[name-defined]
        message_id = await pubsub_transportpublish_task(envelope)  # type: ignore[name-defined]

        API_REQUESTS.labels(endpoint="review-contract", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Contract review task has been queued",
            "tracking": {"task_id": envelope.task_id, "message_id": message_id},
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="review-contract", method="POST", status="error").inc()
        logger.error("contract_review_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/legal-compliance/task/{task_id}")
async def get_task_status(
    task_id: str, credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Get status of a specific task"""
    try:
        task_status = await supabase_transportget_task_status(task_id)  # type: ignore[name-defined]

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
    """Handle HTTP exceptions"""
    return {"error": exc.detail, "status_code": exc.status_code}


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions"""
    logger.error("unhandled_exception", error=str(exc))
    return {"error": "Internal server error", "status_code": 500}
