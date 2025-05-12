"""
Research Crew implementation for performing research tasks.
"""

from typing import Dict, Any, List, Optional
import os
from crewai import Agent, Task, Crew
from langchain.tools import Tool
from langchain.tools.tavily_search import TavilySearchResults

from crewai_service.crews.base_crew import BaseCrew
from crewai_service.tools import RagQueryTool
import structlog

logger = structlog.get_logger(__name__)

class ResearchCrew(BaseCrew):
    """
    A crew specialized in research tasks.

    This crew consists of:
    1. Research Manager - Plans and oversees the research
    2. Domain Expert - Provides specialized knowledge
    3. Information Analyst - Gathers and analyzes information
    4. Content Writer - Creates final reports
    """

    def __init__(
        self,
        crew_id: Optional[str] = None,
        tenant_id: Optional[str] = None,
        project_id: str = "alfred-agent-platform",
        pubsub_emulator_host: Optional[str] = None,
    ):
        super().__init__(crew_id, tenant_id, project_id, pubsub_emulator_host)

        # Initialize tools
        self.tools = self._setup_tools()

        # Create agents
        self._setup_agents()

        # Create tasks
        self._setup_tasks()

    def _setup_tools(self) -> List[Tool]:
        """Set up research tools."""
        # Define search tool
        search_tool = TavilySearchResults(max_results=5)

        # Define RAG query tool
        rag_tool = RagQueryTool(tenant_id=self.tenant_id)

        # Create list of tools
        tools = [
            search_tool,
            rag_tool
        ]

        return tools
    
    def _setup_agents(self) -> None:
        """Set up research agents."""
        # Research Manager
        research_manager = Agent(
            role="Research Manager",
            goal="Create a comprehensive research plan and coordinate the research team",
            backstory="""You are an experienced research manager with expertise in planning and
            coordinating complex research projects. Your strength is in breaking down research
            questions into manageable components and ensuring all aspects are covered.""",
            verbose=True,
            allow_delegation=True
        )
        
        # Domain Expert
        domain_expert = Agent(
            role="Domain Expert",
            goal="Provide specialized knowledge and validate research findings",
            backstory="""You have deep expertise in multiple domains including
            technology, science, business, and humanities. You can quickly analyze
            information for accuracy and relevance, identifying any gaps or inconsistencies.""",
            verbose=True,
            allow_delegation=True,
            tools=self.tools
        )
        
        # Information Analyst
        information_analyst = Agent(
            role="Information Analyst",
            goal="Gather, organize and analyze information from various sources",
            backstory="""You excel at finding and synthesizing information from 
            diverse sources. You're skilled at distinguishing reliable from unreliable
            information and can extract key insights from large volumes of data.""",
            verbose=True,
            allow_delegation=True,
            tools=self.tools
        )
        
        # Content Writer
        content_writer = Agent(
            role="Content Writer",
            goal="Create clear, comprehensive, and engaging research reports",
            backstory="""You are a talented writer who specializes in creating 
            well-structured and engaging content. You can take complex information
            and make it accessible to different audiences while maintaining accuracy.""",
            verbose=True,
            allow_delegation=False
        )
        
        # Add agents to crew
        self.add_agent(research_manager)
        self.add_agent(domain_expert)
        self.add_agent(information_analyst)
        self.add_agent(content_writer)
    
    def _setup_tasks(self) -> None:
        """Set up research tasks."""
        # Task 1: Create Research Plan
        create_plan = Task(
            description="""
            Develop a comprehensive research plan for the given research topic.
            Identify key questions, required information sources, and potential challenges.
            The plan should include:
            1. Main research questions and sub-questions
            2. Types of information needed
            3. Potential methodologies
            4. Timeline and milestones
            
            Output a structured research plan.
            """,
            expected_output="A comprehensive research plan document",
            agent=self.agents[0]  # Research Manager
        )
        
        # Task 2: Gather Information
        gather_info = Task(
            description="""
            Based on the research plan, gather relevant information from various sources.
            Search for credible and up-to-date information related to the research topic.
            Collect a diverse range of perspectives and data points.
            
            Organize the information in a structured format, categorizing by sub-topic
            and noting the source of each piece of information.
            """,
            expected_output="Organized collection of relevant information with sources",
            agent=self.agents[2],  # Information Analyst
            context=[create_plan]
        )
        
        # Task 3: Analyze Information
        analyze_info = Task(
            description="""
            Review the collected information and provide expert analysis.
            Evaluate the reliability and relevance of the information.
            Identify key insights, patterns, and gaps in the research.
            Provide context and interpretation based on domain expertise.
            
            Output a detailed analysis with key findings and recommendations.
            """,
            expected_output="Expert analysis of research findings",
            agent=self.agents[1],  # Domain Expert
            context=[gather_info]
        )
        
        # Task 4: Create Final Report
        create_report = Task(
            description="""
            Create a comprehensive research report based on the analyzed information.
            The report should be well-structured, clear, and engaging.
            Include an executive summary, key findings, analysis, and recommendations.
            Use appropriate formatting and language for the intended audience.
            
            Produce a final report that effectively communicates the research findings.
            """,
            expected_output="Comprehensive research report",
            agent=self.agents[3],  # Content Writer
            context=[analyze_info]
        )
        
        # Add tasks to crew
        self.add_task(create_plan)
        self.add_task(gather_info)
        self.add_task(analyze_info)
        self.add_task(create_report)
    
    def create_crew(self, **kwargs) -> Crew:
        """Create and configure the Research Crew."""
        crew = super().create_crew(
            process=self._get_process_type(kwargs.get("process_type", "sequential")),
            **kwargs
        )
        return crew
    
    def _get_process_type(self, process_type: str) -> str:
        """Get the process type for the crew."""
        valid_types = ["sequential", "hierarchical"]
        if process_type in valid_types:
            return process_type
        return "sequential"