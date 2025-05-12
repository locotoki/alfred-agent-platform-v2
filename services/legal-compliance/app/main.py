"""Legal Compliance Service FastAPI Application"""

from fastapi import FastAPI, HTTPException, Request, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
import structlog
import redis
from prometheus_client import Counter, Histogram, Gauge

# Import platform integration clients
from app.clients import (
    supabase_client,
    rag_client,
    AuthMiddleware,
    get_current_user,
    security,
    initialize_clients,
    MIGRATION_MODE,
    SERVICE_VERSION
)

from libs.a2a_adapter import A2AEnvelope, PubSubTransport, SupabaseTransport, PolicyMiddleware
from libs.agent_core.health import create_health_app
from agents.legal_compliance import (
    LegalComplianceAgent,
    COMPLIANCE_AUDIT,
    DOCUMENT_ANALYSIS,
    REGULATION_CHECK,
    CONTRACT_REVIEW
)
from agents.legal_compliance.models import (
    ComplianceAuditRequest,
    DocumentAnalysisRequest,
    RegulationCheckRequest,
    ContractReviewRequest
)

logger = structlog.get_logger(__name__)

# Initialize Prometheus metrics
TASK_COUNTER = Counter(
    'legal_compliance_tasks_total',
    'Total tasks processed',
    ['intent', 'status']
)

TASK_DURATION = Histogram(
    'legal_compliance_task_duration_seconds',
    'Task processing duration',
    ['intent']
)

API_REQUESTS = Counter(
    'legal_compliance_api_requests_total',
    'Total API requests',
    ['endpoint', 'method', 'status']
)

ACTIVE_TASKS = Gauge(
    'legal_compliance_active_tasks',
    'Currently processing tasks'
)

# Initialize services
pubsub_transport = PubSubTransport(
    project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform")
)

supabase_transport = SupabaseTransport(
    database_url=os.getenv("DATABASE_URL")
)

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
policy_middleware = PolicyMiddleware(redis_client)

# Initialize the agent
legal_compliance_agent = LegalComplianceAgent(
    pubsub_transport=pubsub_transport,
    supabase_transport=supabase_transport,
    policy_middleware=policy_middleware
)

# Security
security = HTTPBearer()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Startup
    # Initialize platform clients
    await initialize_clients()

    # Initialize legacy services
    await supabase_transport.connect()
    await legal_compliance_agent.start()
    logger.info("legal_compliance_service_started", version=SERVICE_VERSION, mode=MIGRATION_MODE)

    yield

    # Shutdown
    await legal_compliance_agent.stop()
    await supabase_transport.disconnect()
    logger.info("legal_compliance_service_stopped")

app = FastAPI(
    title="Legal Compliance Service",
    description="API for legal compliance audits, document analysis, and regulation checks",
    version="1.0.0",
    lifespan=lifespan
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add authentication middleware
app.add_middleware(AuthMiddleware)

# Add health check endpoints
health_app = create_health_app("legal-compliance", "1.0.0")
app.mount("/health", health_app)

# API Routes
@app.post("/api/v1/legal-compliance/audit-compliance", response_model=None)
async def audit_compliance(
    request: ComplianceAuditRequest,
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Perform compliance audit on submitted documents and processes."""
    API_REQUESTS.labels(endpoint="audit-compliance", method="POST", status="processing").inc()

    try:
        # Create envelope for the task
        envelope = A2AEnvelope(
            intent=COMPLIANCE_AUDIT,
            content=request.dict()
        )

        # Extract tenant ID from request or authentication if available
        tenant_id = None
        if hasattr(request, "tenant_id"):
            tenant_id = request.tenant_id
            envelope["tenant_id"] = tenant_id

        # Store task in platform Supabase first if in hybrid or platform mode
        if MIGRATION_MODE in ("hybrid", "platform"):
            try:
                # Attempt to store in platform Supabase
                platform_task_id = await supabase_client.store_task(envelope)
                if platform_task_id:
                    envelope.task_id = platform_task_id
                    logger.info("Task stored in platform Supabase", task_id=platform_task_id)
            except Exception as e:
                if MIGRATION_MODE == "platform":
                    # In platform-only mode, raise the exception
                    raise e
                # In hybrid mode, log and continue with legacy storage
                logger.warning("Failed to store task in platform Supabase, using legacy storage",
                              error=str(e))

        # Store task in legacy storage if in legacy or hybrid mode
        if MIGRATION_MODE in ("legacy", "hybrid"):
            legacy_task_id = await supabase_transport.store_task(envelope)
            logger.info("Task stored in legacy storage", task_id=legacy_task_id)

        # Publish task
        message_id = await pubsub_transport.publish_task(envelope)

        # Get context from RAG Gateway if available
        legal_context = []
        try:
            if MIGRATION_MODE in ("hybrid", "platform"):
                # Extract compliance categories if available
                compliance_categories = None
                if hasattr(request, "compliance_categories") and request.compliance_categories:
                    compliance_categories = [cat.value if hasattr(cat, "value") else cat for cat in request.compliance_categories]

                # Extract jurisdictions if available
                jurisdictions = None
                if hasattr(request, "jurisdictions") and request.jurisdictions:
                    jurisdictions = [j.value if hasattr(j, "value") else j for j in request.jurisdictions]

                # Get relevant legal context
                legal_context = await rag_client.get_legal_context(
                    query=f"Compliance audit for {', '.join(compliance_categories) if compliance_categories else 'general compliance'}",
                    jurisdictions=jurisdictions,
                    compliance_categories=compliance_categories
                )
                logger.info(f"Retrieved {len(legal_context)} legal context items for compliance audit")

                # Add context to the agent's working memory if available
                if legal_context and hasattr(legal_compliance_agent, 'add_context'):
                    await legal_compliance_agent.add_context(envelope.task_id, legal_context)
        except Exception as e:
            logger.warning(f"Failed to retrieve legal context: {str(e)}")

        API_REQUESTS.labels(endpoint="audit-compliance", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Compliance audit task has been queued",
            "tracking": {
                "task_id": envelope.task_id,
                "message_id": message_id
            }
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="audit-compliance", method="POST", status="error").inc()
        logger.error("compliance_audit_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/legal-compliance/analyze-document", response_model=None)
async def analyze_document(
    request: DocumentAnalysisRequest,
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Analyze legal document for compliance issues."""
    API_REQUESTS.labels(endpoint="analyze-document", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(
            intent=DOCUMENT_ANALYSIS,
            content=request.dict()
        )

        # Extract tenant ID from request or authentication if available
        tenant_id = None
        if hasattr(request, "tenant_id"):
            tenant_id = request.tenant_id
            envelope["tenant_id"] = tenant_id

        # Store task in platform Supabase first if in hybrid or platform mode
        if MIGRATION_MODE in ("hybrid", "platform"):
            try:
                # Attempt to store in platform Supabase
                platform_task_id = await supabase_client.store_task(envelope)
                if platform_task_id:
                    envelope.task_id = platform_task_id
                    logger.info("Task stored in platform Supabase", task_id=platform_task_id)
            except Exception as e:
                if MIGRATION_MODE == "platform":
                    # In platform-only mode, raise the exception
                    raise e
                # In hybrid mode, log and continue with legacy storage
                logger.warning("Failed to store task in platform Supabase, using legacy storage",
                              error=str(e))

        # Store task in legacy storage if in legacy or hybrid mode
        if MIGRATION_MODE in ("legacy", "hybrid"):
            legacy_task_id = await supabase_transport.store_task(envelope)
            logger.info("Task stored in legacy storage", task_id=legacy_task_id)

        # Publish task
        message_id = await pubsub_transport.publish_task(envelope)

        # Get context from RAG Gateway if available
        document_context = []
        try:
            if MIGRATION_MODE in ("hybrid", "platform"):
                # Extract document type if available
                document_type = None
                if hasattr(request, "document_type"):
                    document_type = request.document_type.value if hasattr(request.document_type, "value") else request.document_type

                # Extract jurisdiction if available
                jurisdiction = None
                if hasattr(request, "jurisdiction"):
                    jurisdiction = request.jurisdiction

                # Get relevant document context
                document_context = await rag_client.get_legal_context(
                    query=f"Legal analysis for {document_type or 'document'} in {jurisdiction or 'general'} jurisdiction",
                    document_types=[document_type] if document_type else None,
                    jurisdictions=[jurisdiction] if jurisdiction else None
                )
                logger.info(f"Retrieved {len(document_context)} document context items")

                # Add context to the agent's working memory if available
                if document_context and hasattr(legal_compliance_agent, 'add_context'):
                    await legal_compliance_agent.add_context(envelope.task_id, document_context)
        except Exception as e:
            logger.warning(f"Failed to retrieve document context: {str(e)}")

        API_REQUESTS.labels(endpoint="analyze-document", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Document analysis task has been queued",
            "tracking": {
                "task_id": envelope.task_id,
                "message_id": message_id
            }
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="analyze-document", method="POST", status="error").inc()
        logger.error("document_analysis_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/legal-compliance/check-regulations", response_model=None)
async def check_regulations(
    request: RegulationCheckRequest,
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Check compliance against specific regulations."""
    API_REQUESTS.labels(endpoint="check-regulations", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(
            intent=REGULATION_CHECK,
            content=request.dict()
        )

        # Extract tenant ID from request or authentication if available
        tenant_id = None
        if hasattr(request, "tenant_id"):
            tenant_id = request.tenant_id
            envelope["tenant_id"] = tenant_id

        # Store task in platform Supabase first if in hybrid or platform mode
        if MIGRATION_MODE in ("hybrid", "platform"):
            try:
                # Attempt to store in platform Supabase
                platform_task_id = await supabase_client.store_task(envelope)
                if platform_task_id:
                    envelope.task_id = platform_task_id
                    logger.info("Task stored in platform Supabase", task_id=platform_task_id)
            except Exception as e:
                if MIGRATION_MODE == "platform":
                    # In platform-only mode, raise the exception
                    raise e
                # In hybrid mode, log and continue with legacy storage
                logger.warning("Failed to store task in platform Supabase, using legacy storage",
                              error=str(e))

        # Store task in legacy storage if in legacy or hybrid mode
        if MIGRATION_MODE in ("legacy", "hybrid"):
            legacy_task_id = await supabase_transport.store_task(envelope)
            logger.info("Task stored in legacy storage", task_id=legacy_task_id)

        # Publish task
        message_id = await pubsub_transport.publish_task(envelope)

        # Get context from RAG Gateway if available
        regulation_context = []
        try:
            if MIGRATION_MODE in ("hybrid", "platform"):
                # Extract regulation name if available
                regulation_names = []
                if hasattr(request, "regulations") and request.regulations:
                    regulation_names = [reg.value if hasattr(reg, "value") else reg for reg in request.regulations]

                # Extract jurisdiction if available
                jurisdiction = None
                if hasattr(request, "jurisdiction"):
                    jurisdiction = request.jurisdiction

                # Extract industry if available
                industry = None
                if hasattr(request, "industry"):
                    industry = request.industry

                # Get relevant regulation context for each regulation
                for regulation in regulation_names:
                    regulation_context.extend(await rag_client.get_regulation_context(
                        query=f"Compliance requirements for {regulation} in {industry or 'general'} industry",
                        regulation_name=regulation,
                        jurisdiction=jurisdiction,
                        industry=industry
                    ))

                logger.info(f"Retrieved {len(regulation_context)} regulation context items")

                # Add context to the agent's working memory if available
                if regulation_context and hasattr(legal_compliance_agent, 'add_context'):
                    await legal_compliance_agent.add_context(envelope.task_id, regulation_context)
        except Exception as e:
            logger.warning(f"Failed to retrieve regulation context: {str(e)}")

        API_REQUESTS.labels(endpoint="check-regulations", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Regulation check task has been queued",
            "tracking": {
                "task_id": envelope.task_id,
                "message_id": message_id
            }
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="check-regulations", method="POST", status="error").inc()
        logger.error("regulation_check_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/legal-compliance/review-contract", response_model=None)
async def review_contract(
    request: ContractReviewRequest,
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Review contract for legal compliance and potential issues."""
    API_REQUESTS.labels(endpoint="review-contract", method="POST", status="processing").inc()

    try:
        envelope = A2AEnvelope(
            intent=CONTRACT_REVIEW,
            content=request.dict()
        )

        # Extract tenant ID from request or authentication if available
        tenant_id = None
        if hasattr(request, "tenant_id"):
            tenant_id = request.tenant_id
            envelope["tenant_id"] = tenant_id

        # Store task in platform Supabase first if in hybrid or platform mode
        if MIGRATION_MODE in ("hybrid", "platform"):
            try:
                # Attempt to store in platform Supabase
                platform_task_id = await supabase_client.store_task(envelope)
                if platform_task_id:
                    envelope.task_id = platform_task_id
                    logger.info("Task stored in platform Supabase", task_id=platform_task_id)
            except Exception as e:
                if MIGRATION_MODE == "platform":
                    # In platform-only mode, raise the exception
                    raise e
                # In hybrid mode, log and continue with legacy storage
                logger.warning("Failed to store task in platform Supabase, using legacy storage",
                              error=str(e))

        # Store task in legacy storage if in legacy or hybrid mode
        if MIGRATION_MODE in ("legacy", "hybrid"):
            legacy_task_id = await supabase_transport.store_task(envelope)
            logger.info("Task stored in legacy storage", task_id=legacy_task_id)

        # Publish task
        message_id = await pubsub_transport.publish_task(envelope)

        # Get context from RAG Gateway if available
        contract_context = []
        try:
            if MIGRATION_MODE in ("hybrid", "platform"):
                # Extract contract type if available
                contract_type = None
                if hasattr(request, "contract_type"):
                    contract_type = request.contract_type.value if hasattr(request.contract_type, "value") else request.contract_type

                # Extract jurisdiction if available
                jurisdiction = None
                if hasattr(request, "jurisdiction"):
                    jurisdiction = request.jurisdiction

                # Get relevant contract context
                contract_context = await rag_client.get_contract_context(
                    query=f"Legal contract review for {contract_type or 'general'} in {jurisdiction or 'general'} jurisdiction",
                    contract_type=contract_type,
                    jurisdiction=jurisdiction
                )
                logger.info(f"Retrieved {len(contract_context)} contract context items")

                # Add context to the agent's working memory if available
                if contract_context and hasattr(legal_compliance_agent, 'add_context'):
                    await legal_compliance_agent.add_context(envelope.task_id, contract_context)
        except Exception as e:
            logger.warning(f"Failed to retrieve contract context: {str(e)}")

        API_REQUESTS.labels(endpoint="review-contract", method="POST", status="success").inc()

        return {
            "status": "accepted",
            "task_id": envelope.task_id,
            "message": "Contract review task has been queued",
            "tracking": {
                "task_id": envelope.task_id,
                "message_id": message_id
            }
        }
    except Exception as e:
        API_REQUESTS.labels(endpoint="review-contract", method="POST", status="error").inc()
        logger.error("contract_review_api_error", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/legal-compliance/task/{task_id}", response_model=None)
async def get_task_status(
    task_id: str,
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Get status of a specific task."""
    try:
        # Try platform Supabase first if in hybrid or platform mode
        task_status = None
        platform_status_attempted = False

        if MIGRATION_MODE in ("hybrid", "platform"):
            try:
                platform_status_attempted = True
                task_status = await supabase_client.get_task_status(task_id)

                if task_status:
                    logger.info("Task status retrieved from platform Supabase", task_id=task_id)
                    return task_status
                elif MIGRATION_MODE == "platform":
                    # In platform-only mode, if not found, return 404
                    raise HTTPException(status_code=404, detail="Task not found")
            except HTTPException as he:
                # If it's an HTTPException, re-raise it immediately
                if MIGRATION_MODE == "platform":
                    raise he
                logger.warning("Failed to get task status from platform Supabase",
                              error=str(he), task_id=task_id)
            except Exception as e:
                # For other exceptions, log and continue with legacy if in hybrid mode
                if MIGRATION_MODE == "platform":
                    raise e
                logger.warning("Error retrieving task status from platform Supabase",
                              error=str(e), task_id=task_id)

        # Fall back to legacy storage if necessary
        if MIGRATION_MODE in ("legacy", "hybrid") and not task_status:
            try:
                task_status = await supabase_transport.get_task_status(task_id)

                if task_status:
                    logger.info("Task status retrieved from legacy storage", task_id=task_id)
                    return task_status
            except Exception as e:
                logger.warning("Error retrieving task status from legacy storage",
                              error=str(e), task_id=task_id)

        # If we get here and task_status is still None, the task was not found
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
