"""
Base class for CrewAI crews that integrates with Alfred Agent Platform.
"""

from typing import Dict, Any, List, Optional, Union
import uuid
import time
import asyncio
import json
from google.cloud import pubsub_v1
from crewai import Crew, Agent, Task
import structlog

logger = structlog.get_logger(__name__)

class BaseCrew:
    """Base class for CrewAI crews that integrates with Alfred Agent Platform."""
    
    def __init__(
        self,
        crew_id: Optional[str] = None,
        tenant_id: Optional[str] = None,
        project_id: str = "alfred-agent-platform",
        pubsub_emulator_host: Optional[str] = None,
    ):
        self.crew_id = crew_id or str(uuid.uuid4())
        self.tenant_id = tenant_id
        self.project_id = project_id
        self.pubsub_emulator_host = pubsub_emulator_host
        
        # Initialize PubSub clients
        self.publisher = pubsub_v1.PublisherClient()
        self.results_topic_path = self.publisher.topic_path(
            self.project_id, "crew.results"
        )
        
        # Initialize base crew components
        self.agents: List[Agent] = []
        self.tasks: List[Task] = []
        self.crew: Optional[Crew] = None
    
    def add_agent(self, agent: Agent) -> None:
        """Add an agent to the crew."""
        self.agents.append(agent)
    
    def add_task(self, task: Task) -> None:
        """Add a task to the crew."""
        self.tasks.append(task)
    
    def create_crew(self, **kwargs) -> Crew:
        """Create and configure the CrewAI crew."""
        self.crew = Crew(
            agents=self.agents,
            tasks=self.tasks,
            verbose=True,
            **kwargs
        )
        return self.crew
    
    async def run(self, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Run the crew and publish results to PubSub."""
        if not self.crew:
            self.create_crew()
        
        start_time = time.time()
        
        try:
            # Execute crew tasks
            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: self.crew.kickoff(inputs=context or {})
            )
            
            # Process and format result
            execution_time = time.time() - start_time
            processed_result = self._process_result(result, execution_time)
            
            # Publish result to PubSub
            await self._publish_result(processed_result)
            
            return processed_result
            
        except Exception as e:
            error_result = {
                "crew_id": self.crew_id,
                "status": "error",
                "error": str(e),
                "execution_time": time.time() - start_time
            }
            await self._publish_result(error_result)
            logger.error("crew_execution_error", error=str(e), crew_id=self.crew_id)
            raise
    
    def _process_result(self, result: Any, execution_time: float) -> Dict[str, Any]:
        """Process and structure the crew execution result."""
        return {
            "crew_id": self.crew_id,
            "tenant_id": self.tenant_id,
            "status": "completed",
            "result": result if isinstance(result, dict) else {"output": str(result)},
            "execution_time": execution_time,
            "timestamp": time.time(),
            "agents": [agent.name for agent in self.agents],
            "tasks": [task.description for task in self.tasks]
        }
    
    async def _publish_result(self, result: Dict[str, Any]) -> None:
        """Publish result to the appropriate PubSub topic."""
        message = json.dumps(result).encode("utf-8")
        try:
            future = self.publisher.publish(self.results_topic_path, message)
            message_id = future.result()
            logger.info(
                "result_published",
                message_id=message_id,
                crew_id=self.crew_id,
                topic="crew.results"
            )
        except Exception as e:
            logger.error(
                "result_publish_error",
                error=str(e),
                crew_id=self.crew_id
            )