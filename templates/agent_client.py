"""
Agent Client Template

This module provides a standardized client for interacting with Alfred Agent Platform services.
It handles:
- Supabase connectivity for message persistence
- Pub/Sub integration for event-based communication
- Error handling and retries
- Metrics collection

Usage:
    from templates.agent_client import AgentClient
    
    client = AgentClient(agent_name="my_agent")
    response = await client.process_request("Do something")
"""

import os
import logging
import json
import uuid
import asyncio
import time
from typing import Dict, Any, Optional, List, Tuple

import httpx
from prometheus_client import Counter, Histogram, Gauge

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("agent_client")

class AgentClient:
    """Client for interacting with Alfred Agent Platform services"""
    
    def __init__(
        self, 
        agent_name: str,
        supabase_url: Optional[str] = None,
        supabase_key: Optional[str] = None,
        pubsub_emulator_host: Optional[str] = None,
        pubsub_project_id: Optional[str] = None,
    ):
        """
        Initialize the agent client
        
        Args:
            agent_name: Name of the agent (used for topic naming and metrics)
            supabase_url: Supabase URL (defaults to env var SUPABASE_URL)
            supabase_key: Supabase service role key (defaults to env var SUPABASE_SERVICE_ROLE_KEY)
            pubsub_emulator_host: Pub/Sub emulator host (defaults to env var PUBSUB_EMULATOR_HOST)
            pubsub_project_id: Pub/Sub project ID (defaults to env var PUBSUB_PROJECT_ID)
        """
        self.agent_name = agent_name
        
        # Supabase configuration
        self.supabase_url = supabase_url or os.getenv("SUPABASE_URL", "http://localhost:54321")
        self.supabase_key = supabase_key or os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
        
        # Pub/Sub configuration
        self.pubsub_host = pubsub_emulator_host or os.getenv("PUBSUB_EMULATOR_HOST", "localhost:8681")
        self.pubsub_project = pubsub_project_id or os.getenv("PUBSUB_PROJECT_ID", "alfred-agent-platform")
        self.topic_in = f"{agent_name}_in"
        self.topic_out = f"{agent_name}_out"
        
        # Set up metrics
        self.request_counter = Counter(
            f"{agent_name}_request_count", 
            f"Number of requests processed by {agent_name}"
        )
        self.processing_time = Histogram(
            f"{agent_name}_processing_seconds", 
            f"Time spent processing requests in {agent_name}",
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, 120.0]
        )
        self.error_counter = Counter(
            f"{agent_name}_error_count", 
            f"Number of errors encountered by {agent_name}"
        )
        self.health_gauge = Gauge(
            f"{agent_name}_health", 
            f"Health status of {agent_name} (1=healthy, 0=unhealthy)"
        )
        self.supabase_gauge = Gauge(
            f"{agent_name}_supabase_reachable", 
            f"Supabase reachability for {agent_name} (1=reachable, 0=unreachable)"
        )
        self.pubsub_gauge = Gauge(
            f"{agent_name}_pubsub_reachable", 
            f"Pub/Sub reachability for {agent_name} (1=reachable, 0=unreachable)"
        )
        
    async def check_health(self) -> bool:
        """
        Check health of all dependencies
        
        Returns:
            True if all dependencies are healthy, False otherwise
        """
        supabase_healthy = await self._check_supabase()
        pubsub_healthy = await self._check_pubsub()
        
        # Update metrics
        self.supabase_gauge.set(1 if supabase_healthy else 0)
        self.pubsub_gauge.set(1 if pubsub_healthy else 0)
        
        # Overall health
        all_healthy = supabase_healthy and pubsub_healthy
        self.health_gauge.set(1 if all_healthy else 0)
        
        return all_healthy
        
    async def _check_supabase(self) -> bool:
        """
        Check Supabase connectivity
        
        Returns:
            True if Supabase is reachable, False otherwise
        """
        if not self.supabase_url or not self.supabase_key:
            logger.warning("Supabase not configured")
            return False
            
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Try to access the agent table
                response = await client.get(
                    f"{self.supabase_url}/rest/v1/{self.topic_out}",
                    headers={
                        "apikey": self.supabase_key,
                        "Authorization": f"Bearer {self.supabase_key}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "select": "id",
                        "limit": "1"
                    }
                )
                
                if response.status_code >= 300:
                    logger.warning(f"Could not access {self.topic_out} table: {response.status_code}")
                    if response.status_code == 404:
                        logger.error(f"Table {self.topic_out} might not exist")
                        logger.info(f"Run ./scripts/setup_agent_tables.sh {self.agent_name} to create it")
                    return False
                    
                # Try write test
                test_id = str(uuid.uuid4())
                test_msg = {
                    "id": test_id,
                    "data": {"test": "connectivity", "timestamp": time.time()}
                }
                
                response = await client.post(
                    f"{self.supabase_url}/rest/v1/{self.topic_out}",
                    headers={
                        "apikey": self.supabase_key,
                        "Authorization": f"Bearer {self.supabase_key}",
                        "Content-Type": "application/json",
                        "Prefer": "return=minimal"
                    },
                    json=test_msg
                )
                
                if response.status_code >= 300:
                    logger.warning(f"Write access check failed: {response.status_code}")
                    return False
                    
                # Clean up test data
                await client.delete(
                    f"{self.supabase_url}/rest/v1/{self.topic_out}",
                    headers={
                        "apikey": self.supabase_key,
                        "Authorization": f"Bearer {self.supabase_key}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "id": f"eq.{test_id}"
                    }
                )
                
                logger.info("Supabase connectivity verified")
                return True
                
        except Exception as e:
            logger.error(f"Error connecting to Supabase: {str(e)}")
            return False
            
    async def _check_pubsub(self) -> bool:
        """
        Check Pub/Sub connectivity
        
        Returns:
            True if Pub/Sub is reachable, False otherwise
        """
        if not self.pubsub_host:
            logger.warning("Pub/Sub not configured")
            return False
            
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Try to access topics
                response = await client.get(
                    f"http://{self.pubsub_host}/v1/projects/{self.pubsub_project}/topics"
                )
                
                if response.status_code >= 300:
                    logger.warning(f"Could not access Pub/Sub topics: {response.status_code}")
                    return False
                
                # Check if our topics exist
                topics = response.json().get("topics", [])
                topic_names = [t.split("/")[-1] for t in topics]
                
                if self.topic_in not in topic_names:
                    logger.warning(f"Topic {self.topic_in} doesn't exist")
                    return False
                    
                if self.topic_out not in topic_names:
                    logger.warning(f"Topic {self.topic_out} doesn't exist")
                    return False
                
                logger.info("Pub/Sub connectivity verified")
                return True
                
        except Exception as e:
            logger.error(f"Error connecting to Pub/Sub: {str(e)}")
            return False
            
    async def store_message(self, message: Dict[str, Any], table: Optional[str] = None) -> str:
        """
        Store a message in Supabase
        
        Args:
            message: The message to store
            table: Optional table name override (defaults to agent output table)
            
        Returns:
            ID of the stored message
        """
        if not self.supabase_url or not self.supabase_key:
            logger.warning(f"Supabase not configured, skipping message storage")
            return str(uuid.uuid4())  # Return fake ID
            
        table = table or self.topic_out
            
        try:
            # Add ID if not present
            if "id" not in message:
                message["id"] = str(uuid.uuid4())
                
            # Create message object with correct structure for JSONB column
            message_obj = {
                "id": message["id"],
                "data": message
            }
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    f"{self.supabase_url}/rest/v1/{table}",
                    headers={
                        "apikey": self.supabase_key,
                        "Authorization": f"Bearer {self.supabase_key}",
                        "Content-Type": "application/json",
                        "Prefer": "return=minimal"
                    },
                    json=message_obj
                )
                
                if response.status_code >= 400:
                    logger.error(f"Error storing message: {response.status_code} {response.text}")
                    if response.status_code == 404:
                        logger.error(f"Table '{table}' may not exist. Run ./scripts/setup_agent_tables.sh to create it.")
                else:
                    response.raise_for_status()
                    logger.info(f"Stored message in {table} with ID {message['id']}")
                
                return message["id"]
                
        except Exception as e:
            logger.error(f"Error storing message: {str(e)}")
            self.error_counter.inc()
            return message.get("id", str(uuid.uuid4()))
            
    async def get_message(self, message_id: str, table: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Retrieve a message from Supabase
        
        Args:
            message_id: The message ID
            table: Optional table name override (defaults to agent output table)
            
        Returns:
            The message or None if not found
        """
        if not self.supabase_url or not self.supabase_key:
            logger.warning(f"Supabase not configured, cannot retrieve message {message_id}")
            return None
            
        table = table or self.topic_out
            
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    f"{self.supabase_url}/rest/v1/{table}",
                    headers={
                        "apikey": self.supabase_key,
                        "Authorization": f"Bearer {self.supabase_key}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "id": f"eq.{message_id}",
                        "select": "*"
                    }
                )
                
                if response.status_code == 404:
                    logger.error(f"Table '{table}' not found")
                    return None
                
                response.raise_for_status()
                messages = response.json()
                
                if messages and len(messages) > 0:
                    # Handle the JSONB data column structure
                    if "data" in messages[0] and isinstance(messages[0]["data"], dict):
                        return messages[0]["data"]
                    else:
                        logger.warning(f"Message {message_id} has unexpected structure")
                        return messages[0]
                
                logger.warning(f"Message {message_id} not found in {table}")
                return None
                
        except Exception as e:
            logger.error(f"Error retrieving message {message_id}: {str(e)}")
            self.error_counter.inc()
            return None
    
    async def publish_message(self, message: Dict[str, Any], topic: Optional[str] = None) -> bool:
        """
        Publish a message to Pub/Sub
        
        Args:
            message: The message to publish
            topic: Optional topic override (defaults to agent output topic)
            
        Returns:
            True if successful, False otherwise
        """
        if not self.pubsub_host:
            logger.warning(f"Pub/Sub not configured, cannot publish message")
            return False
            
        topic = topic or self.topic_out
            
        try:
            # Ensure we have an ID
            if "id" not in message:
                message["id"] = str(uuid.uuid4())
                
            # Encode message as base64
            message_json = json.dumps(message)
            message_bytes = message_json.encode("utf-8")
            import base64
            message_b64 = base64.b64encode(message_bytes).decode("utf-8")
            
            # Create Pub/Sub payload
            payload = {
                "messages": [
                    {
                        "data": message_b64
                    }
                ]
            }
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    f"http://{self.pubsub_host}/v1/projects/{self.pubsub_project}/topics/{topic}:publish",
                    headers={
                        "Content-Type": "application/json"
                    },
                    json=payload
                )
                
                if response.status_code >= 400:
                    logger.error(f"Error publishing message: {response.status_code} {response.text}")
                    return False
                
                response.raise_for_status()
                logger.info(f"Published message to {topic}")
                return True
                
        except Exception as e:
            logger.error(f"Error publishing message: {str(e)}")
            self.error_counter.inc()
            return False
            
    async def process_request(
        self, 
        content: str, 
        msg_type: str = "chat",
        metadata: Optional[Dict[str, Any]] = None,
        task_id: Optional[str] = None,
        parent_id: Optional[str] = None,
        timeout: float = 60.0
    ) -> Optional[Dict[str, Any]]:
        """
        Process a request through the agent and wait for a response
        
        Args:
            content: The message content
            msg_type: The message type
            metadata: Additional metadata
            task_id: Optional task ID (generated if not provided)
            parent_id: Optional parent task ID for threading
            timeout: Maximum time to wait for response in seconds
            
        Returns:
            The agent's response or None if timeout or error
        """
        # Record start time for metrics
        start_time = time.time()
        self.request_counter.inc()
        
        # Generate task ID if not provided
        task_id = task_id or str(uuid.uuid4())
        
        # Create request message
        request = {
            "task_id": task_id,
            "role": self.agent_name,
            "msg_type": msg_type,
            "content": content,
            "metadata": metadata or {
                "parent_id": parent_id,
                "schema_ver": 1
            }
        }
        
        try:
            # Store in Supabase
            await self.store_message(request, self.topic_in)
            
            # Publish to Pub/Sub
            published = await self.publish_message(request, self.topic_in)
            if not published:
                logger.error(f"Failed to publish message to {self.topic_in}")
                self.error_counter.inc()
                return None
                
            # Wait for response
            response = await self._wait_for_response(task_id, timeout)
            
            # Record processing time
            processing_time = time.time() - start_time
            self.processing_time.observe(processing_time)
            
            return response
            
        except Exception as e:
            logger.error(f"Error processing request: {str(e)}")
            self.error_counter.inc()
            return None
            
    async def _wait_for_response(self, task_id: str, timeout: float) -> Optional[Dict[str, Any]]:
        """
        Wait for a response to a specific task
        
        Args:
            task_id: The task ID to wait for
            timeout: Maximum time to wait in seconds
            
        Returns:
            The response message or None if timeout
        """
        start_time = time.time()
        poll_interval = 0.5  # Start with fast polling
        max_poll_interval = 2.0  # Max polling interval
        
        while (time.time() - start_time) < timeout:
            # Check if response exists
            response = await self._check_response(task_id)
            if response:
                return response
                
            # Adaptive polling interval (slower as time passes)
            elapsed = time.time() - start_time
            poll_interval = min(max_poll_interval, 0.5 + (elapsed / 10))
            
            # Wait before checking again
            await asyncio.sleep(poll_interval)
            
        logger.warning(f"Timeout waiting for response to task {task_id}")
        return None
        
    async def _check_response(self, task_id: str) -> Optional[Dict[str, Any]]:
        """
        Check if a response exists for a specific task
        
        Args:
            task_id: The task ID to check
            
        Returns:
            The response message or None if not found
        """
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(
                    f"{self.supabase_url}/rest/v1/{self.topic_out}",
                    headers={
                        "apikey": self.supabase_key,
                        "Authorization": f"Bearer {self.supabase_key}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "select": "*",
                        "data->>task_id": f"eq.{task_id}",
                        "order": "created_at.desc",
                        "limit": "1"
                    }
                )
                
                if response.status_code >= 300:
                    return None
                    
                messages = response.json()
                
                if messages and len(messages) > 0:
                    # Return the data field which contains our message
                    if "data" in messages[0] and isinstance(messages[0]["data"], dict):
                        return messages[0]["data"]
                    
                return None
                
        except Exception as e:
            logger.error(f"Error checking for response: {str(e)}")
            return None