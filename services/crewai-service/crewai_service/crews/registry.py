"""
Registry of available CrewAI crews.
"""

from typing import Dict, Type
from crewai_service.crews.base_crew import BaseCrew
from crewai_service.crews.research_crew import ResearchCrew
from crewai_service.crews.code_review_crew import CodeReviewCrew
from crewai_service.crews.data_analysis_crew import DataAnalysisCrew

# Register all available crews
CREW_REGISTRY: Dict[str, Type[BaseCrew]] = {
    "research": ResearchCrew,
    "code_review": CodeReviewCrew,
    "data_analysis": DataAnalysisCrew,
}