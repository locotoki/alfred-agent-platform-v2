"""Agent BizOps Settings with Legacy Environment Variable Support."""

import os
import warnings
from typing import Dict, List, Optional


class LegacyEnvVarWarning(DeprecationWarning):
    """Custom warning for deprecated environment variables."""

    pass


def get_env_with_deprecation_warning(
    new_var: str, old_vars: List[str], default: Optional[str] = None
) -> Optional[str]:
    """Get environment variable with deprecation warning for old names."""
    # Check new variable first
    value = os.getenv(new_var)
    if value is not None:
        return value

    # Check legacy variables and emit warnings
    for old_var in old_vars:
        value = os.getenv(old_var)
        if value is not None:
            warnings.warn(
                f"Environment variable '{old_var}' is deprecated. "
                f"Please use '{new_var}' instead. "
                f"Support for '{old_var}' will be removed in the next release.",
                LegacyEnvVarWarning,
                stacklevel=2,
            )
            return value

    return default


class BizOpsSettings:
    """Centralized settings for Agent BizOps service."""

    def __init__(self):
        """Initialize BizOps settings with environment variable mapping."""
        # Workflows configuration
        self.workflows_enabled = self._get_workflows_enabled()

        # API Keys with legacy support
        self.legal_api_key = get_env_with_deprecation_warning(
            "BIZOPS_LEGAL_API_KEY",
            ["LEGAL_COMPLIANCE_API_KEY", "AGENT_LEGAL_API_KEY"],
            "legal-default-key",
        )

        self.finance_api_key = get_env_with_deprecation_warning(
            "BIZOPS_FINANCE_API_KEY",
            ["FINANCIAL_TAX_API_KEY", "AGENT_FINANCIAL_API_KEY"],
            "finance-default-key",
        )

        # Database URLs with legacy support
        self.database_url = get_env_with_deprecation_warning(
            "BIZOPS_DATABASE_URL", ["ALFRED_DATABASE_URL", "DATABASE_URL"]
        )

        # Redis URLs with legacy support
        self.redis_url = get_env_with_deprecation_warning(
            "BIZOPS_REDIS_URL", ["ALFRED_REDIS_URL", "REDIS_URL"], "redis://redis:6379"
        )

        # RAG configuration
        self.rag_url = get_env_with_deprecation_warning(
            "BIZOPS_RAG_URL", ["ALFRED_RAG_URL"], "http://agent-rag:8501"
        )

        self.rag_legal_api_key = get_env_with_deprecation_warning(
            "BIZOPS_RAG_LEGAL_KEY", ["ALFRED_RAG_LEGAL_KEY", "LEGAL_RAG_KEY"], "legal-key"
        )

        self.rag_finance_api_key = get_env_with_deprecation_warning(
            "BIZOPS_RAG_FINANCE_KEY",
            ["ALFRED_RAG_FINANCE_KEY", "FINANCIAL_RAG_KEY"],
            "financial-key",
        )

        # Model Router
        self.model_router_url = get_env_with_deprecation_warning(
            "BIZOPS_MODEL_ROUTER_URL", ["ALFRED_MODEL_ROUTER_URL"], "http://model-router:8080"
        )

        # OpenAI API Key
        self.openai_api_key = get_env_with_deprecation_warning(
            "BIZOPS_OPENAI_API_KEY",
            ["ALFRED_OPENAI_API_KEY", "OPENAI_API_KEY"],
            "sk-mock-key-for-development-only",
        )

    def _get_workflows_enabled(self) -> List[str]:
        """Get enabled workflows from environment."""
        workflows_str = os.getenv("WORKFLOWS_ENABLED", "finance,legal")
        return [w.strip() for w in workflows_str.split(",") if w.strip()]

    def is_workflow_enabled(self, workflow: str) -> bool:
        """Check if a specific workflow is enabled."""
        return workflow.lower() in [w.lower() for w in self.workflows_enabled]

    def get_legacy_mapping(self) -> Dict[str, Dict[str, str]]:
        """Get mapping of new to old environment variables."""
        return {
            "api_keys": {
                "BIZOPS_LEGAL_API_KEY": ["LEGAL_COMPLIANCE_API_KEY", "AGENT_LEGAL_API_KEY"],
                "BIZOPS_FINANCE_API_KEY": ["FINANCIAL_TAX_API_KEY", "AGENT_FINANCIAL_API_KEY"],
            },
            "database": {
                "BIZOPS_DATABASE_URL": ["ALFRED_DATABASE_URL", "DATABASE_URL"],
                "BIZOPS_REDIS_URL": ["ALFRED_REDIS_URL", "REDIS_URL"],
            },
            "services": {
                "BIZOPS_RAG_URL": ["ALFRED_RAG_URL"],
                "BIZOPS_MODEL_ROUTER_URL": ["ALFRED_MODEL_ROUTER_URL"],
                "BIZOPS_OPENAI_API_KEY": ["ALFRED_OPENAI_API_KEY", "OPENAI_API_KEY"],
            },
        }


# Global settings instance
settings = BizOpsSettings()
