"""
Data Analysis Crew implementation for performing data analysis tasks.
"""

from typing import Dict, Any, List, Optional
import os
from crewai import Agent, Task, Crew

from crewai_service.crews.base_crew import BaseCrew
import structlog

logger = structlog.get_logger(__name__)

class DataAnalysisCrew(BaseCrew):
    """
    A crew specialized in data analysis tasks.
    
    This crew consists of:
    1. Data Science Manager - Oversees the analysis process
    2. Data Engineer - Prepares and transforms the data
    3. Data Analyst - Performs statistical analysis
    4. Data Visualization Expert - Creates visualizations and reports
    """
    
    def __init__(
        self,
        crew_id: Optional[str] = None,
        tenant_id: Optional[str] = None,
        project_id: str = "alfred-agent-platform",
        pubsub_emulator_host: Optional[str] = None,
    ):
        super().__init__(crew_id, tenant_id, project_id, pubsub_emulator_host)
        
        # Create agents
        self._setup_agents()
        
        # Create tasks
        self._setup_tasks()
    
    def _setup_agents(self) -> None:
        """Set up data analysis agents."""
        # Data Science Manager
        ds_manager = Agent(
            role="Data Science Manager",
            goal="Plan and oversee the data analysis process",
            backstory="""You are an experienced data science manager who has led numerous
            analytics projects across various domains. You excel at understanding business
            requirements and translating them into data analysis plans. Your expertise includes
            defining meaningful metrics, setting up analysis methodologies, and ensuring
            insights are actionable.""",
            verbose=True,
            allow_delegation=True
        )
        
        # Data Engineer
        data_engineer = Agent(
            role="Data Engineer",
            goal="Prepare and transform data for analysis",
            backstory="""You are a skilled data engineer with extensive experience in data
            processing pipelines and ETL processes. You're proficient in handling various
            data formats, cleaning messy datasets, and optimizing data structures for analysis.
            You have deep knowledge of data quality issues and how to address them.""",
            verbose=True,
            allow_delegation=False
        )
        
        # Data Analyst
        data_analyst = Agent(
            role="Data Analyst",
            goal="Perform statistical analysis and extract insights",
            backstory="""You are a data analyst with strong statistical knowledge and
            analytical skills. You're experienced in exploratory data analysis, hypothesis
            testing, and predictive modeling. You can identify patterns, outliers, and
            trends in data, and you're adept at interpreting analytical results in
            business contexts.""",
            verbose=True,
            allow_delegation=False
        )
        
        # Data Visualization Expert
        viz_expert = Agent(
            role="Data Visualization Expert",
            goal="Create clear and insightful data visualizations",
            backstory="""You specialize in data visualization and storytelling with data.
            With a background in both design and data science, you can translate complex
            analytical findings into clear, compelling visuals. You have expertise in
            choosing the right visualization types for different data and insights.""",
            verbose=True,
            allow_delegation=False
        )
        
        # Add agents to crew
        self.add_agent(ds_manager)
        self.add_agent(data_engineer)
        self.add_agent(data_analyst)
        self.add_agent(viz_expert)
    
    def _setup_tasks(self) -> None:
        """Set up data analysis tasks."""
        # Task 1: Define Analysis Plan
        define_plan = Task(
            description="""
            Create a comprehensive data analysis plan based on the given objectives.
            Define the analysis scope, key questions to answer, and required metrics.
            Identify necessary data sources and potential analysis approaches.
            Consider constraints and limitations that might affect the analysis.
            
            Output a structured analysis plan with clear objectives and methodologies.
            """,
            expected_output="Comprehensive data analysis plan",
            agent=self.agents[0]  # Data Science Manager
        )
        
        # Task 2: Data Preparation
        data_prep = Task(
            description="""
            Prepare and transform the provided data for analysis.
            Assess data quality and completeness.
            Clean the data by handling missing values, outliers, and inconsistencies.
            Transform variables as needed (normalization, encoding, etc.).
            Create derived features that might be useful for analysis.
            
            Output a report on the data preparation process and a description of the prepared dataset.
            """,
            expected_output="Data preparation report and cleaned dataset",
            agent=self.agents[1],  # Data Engineer
            context=[define_plan]
        )
        
        # Task 3: Exploratory Analysis
        exploratory_analysis = Task(
            description="""
            Perform exploratory data analysis on the prepared dataset.
            Calculate descriptive statistics for key variables.
            Identify distributions, patterns, trends, and anomalies.
            Examine relationships between variables and potential correlations.
            Test hypotheses relevant to the analysis objectives.
            
            Output a detailed exploratory analysis report with key findings.
            """,
            expected_output="Exploratory analysis report",
            agent=self.agents[2],  # Data Analyst
            context=[define_plan, data_prep]
        )
        
        # Task 4: Create Visualizations
        create_viz = Task(
            description="""
            Create compelling visualizations based on the exploratory analysis.
            Design charts and graphs that effectively communicate key insights.
            Ensure visualizations are clear, accurate, and accessible.
            Create both exploratory and explanatory visualizations as appropriate.
            Annotate visualizations with important context and findings.
            
            Output a set of visualizations with explanations.
            """,
            expected_output="Data visualization portfolio",
            agent=self.agents[3],  # Data Visualization Expert
            context=[exploratory_analysis]
        )
        
        # Task 5: Final Analysis Report
        final_report = Task(
            description="""
            Create a comprehensive final report that synthesizes all analysis findings.
            Summarize the analysis objectives, methodology, and key results.
            Include the most important insights and their business implications.
            Incorporate relevant visualizations to support the narrative.
            Provide actionable recommendations based on the analysis.
            Address limitations and suggest areas for further investigation.
            
            Output a final analysis report suitable for business stakeholders.
            """,
            expected_output="Final data analysis report",
            agent=self.agents[0],  # Data Science Manager
            context=[exploratory_analysis, create_viz]
        )
        
        # Add tasks to crew
        self.add_task(define_plan)
        self.add_task(data_prep)
        self.add_task(exploratory_analysis)
        self.add_task(create_viz)
        self.add_task(final_report)
    
    def create_crew(self, **kwargs) -> Crew:
        """Create and configure the Data Analysis Crew."""
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