"""Alert Explanation Agent.

This agent consumes alert payloads and generates human-readable explanations
with suggested remediation steps and runbook links.
"""

import logging
from typing import Any, Dict, Optional

from langchain.chains import LLMChain
from langchain.llms.base import LLM
from langchain.prompts import PromptTemplate

logger = logging.getLogger(__name__)


class ExplainerAgent:
    """Agent that generates explanations for alerts."""

    def __init__(self, llm: Optional[LLM] = None):
        """Initialize the agent with optional LLM configuration."""
        self.llm = llm
        self._chain: Optional[LLMChain] = None
        self._setup_chain()

    def _setup_chain(self) -> None:
        """Set up the LangChain for alert explanation."""
        if not self.llm:
            logger.warning("No LLM configured, using stub mode")
            return

        prompt = PromptTemplate(
            input_variables=["alert_name", "alert_details", "metric_value"],
            template="""
You are an expert Site Reliability Engineer. Generate a concise explanation for the following alert:

Alert: {alert_name}
Details: {alert_details}
Current Value: {metric_value}

Please provide:
1. A brief explanation of what this alert means
2. Potential causes
3. Suggested remediation steps
4. A link to the runbook (if available)

Format your response as:
Explanation: <brief explanation>
Potential Causes: <list of causes>
Remediation: <steps to fix>
Runbook: <link if available>
""",
        )

        self._chain = LLMChain(llm=self.llm, prompt=prompt)

    def explain_alert(self, alert_payload: Dict[str, Any]) -> Dict[str, Any]:
        """Generate an explanation for the given alert.

        Args:
            alert_payload: The alert notification payload

        Returns:
            Dict containing the explanation and metadata
        """
        alert_name = alert_payload.get("alert_name", "Unknown")
        alert_details = alert_payload.get("description", "No details provided")
        metric_value = alert_payload.get("value", "N/A")

        logger.info(f"Explaining alert: {alert_name}")

        if not self._chain:
            # Stub mode
            return self._generate_stub_explanation(alert_name, alert_details)

        try:
            explanation = self._chain.run(
                alert_name=alert_name, alert_details=alert_details, metric_value=metric_value
            )

            return {"alert_name": alert_name, "explanation": explanation, "success": True}
        except Exception as e:
            logger.error(f"Failed to generate explanation: {e}")
            return {
                "alert_name": alert_name,
                "explanation": f"Failed to generate explanation: {str(e)}",
                "success": False,
            }

    def _generate_stub_explanation(self, alert_name: str, alert_details: str) -> Dict[str, Any]:
        """Generate a stub explanation for testing."""
        return {
            "alert_name": alert_name,
            "explanation": f"""Explanation: This is a stub explanation for {alert_name}
Potential Causes: Stub mode - no LLM configured
Remediation: Configure a proper LLM for real explanations
Runbook: https://example.com/runbooks/{alert_name.lower().replace(' ', '-')}""",
            "success": True,
        }
