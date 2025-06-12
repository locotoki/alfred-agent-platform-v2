"""Alfred agents module.

This module provides agent implementations including intent routing and orchestration
capabilities.
"""

from alfred.agents.intent_router import Intent, IntentRouterLFfrom alfred.agents.orchestrator import AgentOrchestrator, routerLFLF# Create a default orchestrator instanceLForchestrator = AgentOrchestrator()LF
__all__ = ["Intent", "IntentRouter", "router", "AgentOrchestrator", "orchestrator"]
