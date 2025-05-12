"""
Code Review Crew implementation for performing code reviews.
"""

from typing import Dict, Any, List, Optional
import os
from crewai import Agent, Task, Crew

from crewai_service.crews.base_crew import BaseCrew
import structlog

logger = structlog.get_logger(__name__)

class CodeReviewCrew(BaseCrew):
    """
    A crew specialized in code review tasks.
    
    This crew consists of:
    1. Technical Lead - Oversees the entire review process
    2. Security Engineer - Focuses on security vulnerabilities
    3. Performance Engineer - Analyzes code for performance issues
    4. Code Quality Expert - Ensures code follows best practices
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
        """Set up code review agents."""
        # Technical Lead
        tech_lead = Agent(
            role="Technical Lead",
            goal="Oversee the code review process and ensure comprehensive evaluation",
            backstory="""You are an experienced technical lead with a broad understanding
            of software development best practices across multiple languages and frameworks.
            You've led numerous development teams and have a keen eye for architectural
            issues and technical debt.""",
            verbose=True,
            allow_delegation=True
        )
        
        # Security Engineer
        security_engineer = Agent(
            role="Security Engineer",
            goal="Identify and analyze security vulnerabilities in the code",
            backstory="""You are a security specialist with experience in penetration testing
            and secure coding practices. You're familiar with OWASP Top 10 vulnerabilities,
            common attack vectors, and secure coding patterns across various programming languages.""",
            verbose=True,
            allow_delegation=False
        )
        
        # Performance Engineer
        performance_engineer = Agent(
            role="Performance Engineer",
            goal="Analyze code for performance bottlenecks and optimization opportunities",
            backstory="""You specialize in software performance optimization with expertise
            in identifying algorithmic inefficiencies, memory leaks, and resource utilization issues.
            You have extensive experience with profiling tools and performance benchmarking.""",
            verbose=True,
            allow_delegation=False
        )
        
        # Code Quality Expert
        code_quality_expert = Agent(
            role="Code Quality Expert",
            goal="Ensure code follows best practices and is maintainable",
            backstory="""You're passionate about clean code principles, design patterns,
            and maintainable software architecture. You have experience implementing and
            enforcing coding standards across large codebases and development teams.""",
            verbose=True,
            allow_delegation=False
        )
        
        # Add agents to crew
        self.add_agent(tech_lead)
        self.add_agent(security_engineer)
        self.add_agent(performance_engineer)
        self.add_agent(code_quality_expert)
    
    def _setup_tasks(self) -> None:
        """Set up code review tasks."""
        # Task 1: Initial Code Assessment
        initial_assessment = Task(
            description="""
            Perform an initial assessment of the provided code.
            Identify the programming language, framework, and overall structure.
            Determine the code's purpose and main functionality.
            Note any immediate concerns or red flags that require deeper review.
            
            Output a high-level overview of the code and prioritized areas for review.
            """,
            expected_output="Initial code assessment report",
            agent=self.agents[0]  # Technical Lead
        )
        
        # Task 2: Security Analysis
        security_analysis = Task(
            description="""
            Review the code for security vulnerabilities and weaknesses.
            Check for issues such as:
            - Injection vulnerabilities (SQL, NoSQL, command injection, etc.)
            - Authentication and authorization flaws
            - Sensitive data exposure
            - Insecure cryptographic implementations
            - Input validation issues
            
            Provide a detailed security analysis with specific line references and recommendations.
            """,
            expected_output="Security analysis report",
            agent=self.agents[1],  # Security Engineer
            context=[initial_assessment]
        )
        
        # Task 3: Performance Review
        performance_review = Task(
            description="""
            Analyze the code for performance issues and optimization opportunities.
            Look for:
            - Algorithmic inefficiencies
            - Database query optimizations
            - Memory management issues
            - Resource utilization problems
            - Concurrency and threading concerns
            
            Provide a detailed performance analysis with specific recommendations for improvement.
            """,
            expected_output="Performance analysis report",
            agent=self.agents[2],  # Performance Engineer
            context=[initial_assessment]
        )
        
        # Task 4: Code Quality Assessment
        quality_assessment = Task(
            description="""
            Evaluate the code quality and maintainability.
            Review for:
            - Adherence to language-specific best practices
            - Code organization and structure
            - Variable and function naming
            - Documentation and comments
            - Test coverage and testability
            - Duplication and potential refactoring opportunities
            
            Provide a detailed code quality assessment with specific recommendations.
            """,
            expected_output="Code quality assessment report",
            agent=self.agents[3],  # Code Quality Expert
            context=[initial_assessment]
        )
        
        # Task 5: Final Review Summary
        final_summary = Task(
            description="""
            Create a comprehensive code review summary based on all previous analyses.
            Compile and prioritize findings from the security, performance, and quality reviews.
            Categorize issues by severity and effort required to address.
            Provide actionable recommendations for improvement with clear next steps.
            
            Output a final code review report suitable for the development team.
            """,
            expected_output="Final code review report",
            agent=self.agents[0],  # Technical Lead
            context=[security_analysis, performance_review, quality_assessment]
        )
        
        # Add tasks to crew
        self.add_task(initial_assessment)
        self.add_task(security_analysis)
        self.add_task(performance_review)
        self.add_task(quality_assessment)
        self.add_task(final_summary)
    
    def create_crew(self, **kwargs) -> Crew:
        """Create and configure the Code Review Crew."""
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