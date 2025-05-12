"""
Enhanced Supabase client for legal-compliance service.
Provides improved persistence and recovery capabilities.
"""

import os
import json
import uuid
import httpx
import asyncio
import structlog
from typing import Dict, Any, Optional, List
from datetime import datetime

logger = structlog.get_logger(__name__)

# Environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL", "http://supabase-rest:3000")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
USE_SUPABASE = os.getenv("USE_SUPABASE", "true").lower() in ("true", "1", "yes")

# Define table names
LEGAL_IN_TABLE = "legal_in"
LEGAL_OUT_TABLE = "legal_out"


class SupabaseClient:
    """
    Enhanced Supabase client for the legal-compliance service.
    Provides improved persistence and task management.
    """
    
    @staticmethod
    async def check_connection() -> bool:
        """
        Check if Supabase is reachable and tables exist.
        
        Returns:
            True if Supabase is reachable, False otherwise
        """
        global USE_SUPABASE
        
        if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
            logger.warning("Supabase not configured")
            USE_SUPABASE = False
            return False
        
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Check if tables exist
                response = await client.get(
                    f"{SUPABASE_URL}/rest/v1/{LEGAL_OUT_TABLE}",
                    headers={
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "select": "id",
                        "limit": "1"
                    }
                )
                
                if response.status_code >= 300:
                    if response.status_code == 404:
                        logger.warning(f"Tables not found. Please run setup script to create tables.")
                    else:
                        logger.warning(f"Failed to connect to Supabase: {response.status_code}")
                    
                    USE_SUPABASE = False
                    return False
                
                # Test write access with a test record
                test_id = str(uuid.uuid4())
                test_msg = {
                    "id": test_id,
                    "data": {
                        "test": "connectivity",
                        "timestamp": datetime.now().isoformat()
                    }
                }
                
                response = await client.post(
                    f"{SUPABASE_URL}/rest/v1/{LEGAL_OUT_TABLE}",
                    headers={
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "Content-Type": "application/json",
                        "Prefer": "return=minimal"
                    },
                    json=test_msg
                )
                
                if response.status_code >= 300:
                    logger.warning(f"Write access test failed: {response.status_code}")
                    USE_SUPABASE = False
                    return False
                
                # Clean up test data
                await client.delete(
                    f"{SUPABASE_URL}/rest/v1/{LEGAL_OUT_TABLE}",
                    headers={
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "id": f"eq.{test_id}"
                    }
                )
                
                logger.info("Successfully connected to Supabase")
                return True
                
        except Exception as e:
            logger.error(f"Error connecting to Supabase: {str(e)}")
            USE_SUPABASE = False
            return False
    
    @staticmethod
    async def store_task(envelope: Dict[str, Any]) -> str:
        """
        Store a task in Supabase.
        
        Args:
            envelope: Task envelope
            
        Returns:
            Task ID
        """
        if not USE_SUPABASE:
            logger.warning("Supabase not configured, skipping task storage")
            return envelope.get("task_id", str(uuid.uuid4()))
        
        try:
            # Ensure task has an ID
            if "task_id" not in envelope:
                envelope["task_id"] = str(uuid.uuid4())
            
            # Add timestamp if not present
            if "timestamp" not in envelope:
                envelope["timestamp"] = datetime.now().isoformat()
            
            # Create message object
            message_obj = {
                "id": envelope["task_id"],
                "data": envelope,
                "tenant_id": envelope.get("tenant_id", "default")
            }
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    f"{SUPABASE_URL}/rest/v1/{LEGAL_IN_TABLE}",
                    headers={
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "Content-Type": "application/json",
                        "Prefer": "return=minimal"
                    },
                    json=message_obj
                )
                
                if response.status_code >= 400:
                    logger.error(f"Error storing task: {response.status_code} {response.text}")
                    if response.status_code == 404:
                        logger.error(f"Table '{LEGAL_IN_TABLE}' may not exist. Run setup script.")
                else:
                    response.raise_for_status()
                    logger.info(f"Stored task in Supabase: {envelope['task_id']}")
                
                return envelope["task_id"]
                
        except Exception as e:
            logger.error(f"Error storing task in Supabase: {str(e)}")
            return envelope.get("task_id", str(uuid.uuid4()))
    
    @staticmethod
    async def store_result(task_id: str, result: Dict[str, Any], tenant_id: Optional[str] = None) -> bool:
        """
        Store a task result in Supabase.
        
        Args:
            task_id: Task ID
            result: Task result
            tenant_id: Optional tenant ID for multi-tenancy
            
        Returns:
            True if successful, False otherwise
        """
        if not USE_SUPABASE:
            logger.warning("Supabase not configured, skipping result storage")
            return False
        
        try:
            # Create message object
            message_obj = {
                "id": task_id,
                "data": {
                    "task_id": task_id,
                    "result": result,
                    "timestamp": datetime.now().isoformat(),
                    "status": "completed"
                },
                "tenant_id": tenant_id or "default"
            }
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    f"{SUPABASE_URL}/rest/v1/{LEGAL_OUT_TABLE}",
                    headers={
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "Content-Type": "application/json",
                        "Prefer": "return=minimal"
                    },
                    json=message_obj
                )
                
                if response.status_code >= 400:
                    logger.error(f"Error storing result: {response.status_code} {response.text}")
                    if response.status_code == 404:
                        logger.error(f"Table '{LEGAL_OUT_TABLE}' may not exist. Run setup script.")
                    return False
                
                response.raise_for_status()
                logger.info(f"Stored result in Supabase: {task_id}")
                return True
                
        except Exception as e:
            logger.error(f"Error storing result in Supabase: {str(e)}")
            return False
    
    @staticmethod
    async def get_task_status(task_id: str) -> Optional[Dict[str, Any]]:
        """
        Get the status of a task.
        
        Args:
            task_id: Task ID
            
        Returns:
            Task status or None if not found
        """
        if not USE_SUPABASE:
            logger.warning(f"Supabase not configured, cannot get task status: {task_id}")
            return None
        
        try:
            # First check if there's a result
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    f"{SUPABASE_URL}/rest/v1/{LEGAL_OUT_TABLE}",
                    headers={
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "id": f"eq.{task_id}",
                        "select": "*"
                    }
                )
                
                if response.status_code == 200:
                    results = response.json()
                    if results and len(results) > 0:
                        # Task completed
                        return {
                            "task_id": task_id,
                            "status": "completed",
                            "result": results[0].get("data", {}).get("result", {}),
                            "timestamp": results[0].get("data", {}).get("timestamp")
                        }
                
                # If no result, check if task exists
                response = await client.get(
                    f"{SUPABASE_URL}/rest/v1/{LEGAL_IN_TABLE}",
                    headers={
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "Content-Type": "application/json"
                    },
                    params={
                        "id": f"eq.{task_id}",
                        "select": "*"
                    }
                )
                
                if response.status_code == 200:
                    tasks = response.json()
                    if tasks and len(tasks) > 0:
                        # Task exists but not completed
                        return {
                            "task_id": task_id,
                            "status": "processing",
                            "intent": tasks[0].get("data", {}).get("intent"),
                            "timestamp": tasks[0].get("data", {}).get("timestamp")
                        }
                
                # Task not found
                return None
                
        except Exception as e:
            logger.error(f"Error getting task status from Supabase: {str(e)}")
            return None
    
    @staticmethod
    async def list_tasks(
        limit: int = 50, 
        offset: int = 0, 
        status: Optional[str] = None,
        tenant_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        List tasks with optional filtering.
        
        Args:
            limit: Maximum number of tasks to return
            offset: Offset for pagination
            status: Optional status filter (completed, processing)
            tenant_id: Optional tenant ID for multi-tenancy
            
        Returns:
            List of tasks
        """
        if not USE_SUPABASE:
            logger.warning("Supabase not configured, cannot list tasks")
            return []
        
        tasks = []
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Build params
                params = {
                    "select": "*",
                    "order": "created_at.desc",
                    "limit": str(limit),
                    "offset": str(offset)
                }
                
                # Add tenant filter if provided
                if tenant_id:
                    params["tenant_id"] = f"eq.{tenant_id}"
                
                # Get completed tasks
                if status is None or status == "completed":
                    response = await client.get(
                        f"{SUPABASE_URL}/rest/v1/{LEGAL_OUT_TABLE}",
                        headers={
                            "apikey": SUPABASE_SERVICE_ROLE_KEY,
                            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                            "Content-Type": "application/json"
                        },
                        params=params
                    )
                    
                    if response.status_code == 200:
                        completed_tasks = response.json()
                        for task in completed_tasks:
                            if "data" in task and isinstance(task["data"], dict):
                                tasks.append({
                                    "task_id": task["id"],
                                    "status": "completed",
                                    "result": task["data"].get("result", {}),
                                    "timestamp": task["data"].get("timestamp"),
                                    "tenant_id": task.get("tenant_id", "default")
                                })
                
                # Get in-progress tasks
                if status is None or status == "processing":
                    response = await client.get(
                        f"{SUPABASE_URL}/rest/v1/{LEGAL_IN_TABLE}",
                        headers={
                            "apikey": SUPABASE_SERVICE_ROLE_KEY,
                            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                            "Content-Type": "application/json"
                        },
                        params=params
                    )
                    
                    if response.status_code == 200:
                        in_progress_tasks = response.json()
                        for task in in_progress_tasks:
                            # Check if task is already in the list (completed)
                            if not any(t["task_id"] == task["id"] for t in tasks):
                                if "data" in task and isinstance(task["data"], dict):
                                    tasks.append({
                                        "task_id": task["id"],
                                        "status": "processing",
                                        "intent": task["data"].get("intent"),
                                        "timestamp": task["data"].get("timestamp"),
                                        "tenant_id": task.get("tenant_id", "default")
                                    })
                
                # Sort by timestamp
                tasks.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
                
                # Limit to requested number
                tasks = tasks[:limit]
                
                return tasks
                
        except Exception as e:
            logger.error(f"Error listing tasks from Supabase: {str(e)}")
            return []

# Initialize client
supabase_client = SupabaseClient()