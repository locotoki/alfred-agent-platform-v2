"""
Supabase client for social-intel service with file-based fallback.
Provides hybrid storage capabilities during migration to platform services.
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
FILE_FALLBACK = os.getenv("FILE_FALLBACK", "true").lower() in ("true", "1", "yes")

# Define table names
SOCIAL_IN_TABLE = "social_in"
SOCIAL_OUT_TABLE = "social_out"

# Base directories for file fallback
NICHE_SCOUT_DIR = "/app/data/niche_scout"
BLUEPRINT_DIR = "/app/data/blueprint"


class SupabaseClient:
    """
    Hybrid Supabase client that supports both Supabase and file-based storage.
    This allows for a gradual migration to platform services.
    """
    
    @staticmethod
    async def ensure_directories():
        """Ensure the file directories exist for fallback storage"""
        os.makedirs(NICHE_SCOUT_DIR, exist_ok=True)
        os.makedirs(BLUEPRINT_DIR, exist_ok=True)
        
    @staticmethod
    async def check_connection() -> bool:
        """
        Check if Supabase is reachable and tables exist.
        Configures whether to use Supabase or fall back to files.
        
        Returns:
            True if Supabase is reachable, False otherwise
        """
        global USE_SUPABASE
        
        if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
            logger.warning("Supabase not configured - using file-based storage only")
            USE_SUPABASE = False
            return False
        
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Try to access social_out table to verify access
                response = await client.get(
                    f"{SUPABASE_URL}/rest/v1/{SOCIAL_OUT_TABLE}",
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
                
                if response.status_code >= 400:
                    if response.status_code == 404:
                        logger.warning(f"Table '{SOCIAL_OUT_TABLE}' not found. Run setup script to create tables")
                    else:
                        logger.warning(f"Supabase connection failed: {response.status_code} {response.text}")
                    
                    USE_SUPABASE = False
                    return False
                
                logger.info("Successfully connected to Supabase and verified table access")
                return True
                
        except Exception as e:
            logger.error(f"Error connecting to Supabase: {str(e)}")
            USE_SUPABASE = False
            return False
    
    @staticmethod
    async def store_workflow_result(workflow_id: str, data: Dict[str, Any], workflow_type: str = "niche-scout") -> str:
        """
        Store a workflow result in Supabase with file fallback.
        
        Args:
            workflow_id: The workflow ID
            data: The workflow data to store
            workflow_type: Type of workflow (niche-scout or seed-to-blueprint)
            
        Returns:
            The workflow ID
        """
        # Ensure workflow ID
        if not workflow_id:
            workflow_id = str(uuid.uuid4())
            
        # Add ID and timestamp to data if not present
        if isinstance(data, dict):
            if "id" not in data:
                data["id"] = workflow_id
            if "timestamp" not in data:
                data["timestamp"] = datetime.now().isoformat()
        
        # First try to store in Supabase if enabled
        supabase_success = False
        if USE_SUPABASE:
            try:
                # Create a message object with the correct structure for JSONB column
                message_obj = {
                    "id": workflow_id,
                    "data": data
                }
                
                # Store in Supabase
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.post(
                        f"{SUPABASE_URL}/rest/v1/{SOCIAL_OUT_TABLE}",
                        headers={
                            "apikey": SUPABASE_SERVICE_ROLE_KEY,
                            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                            "Content-Type": "application/json",
                            "Prefer": "return=minimal"
                        },
                        json=message_obj
                    )
                    
                    if response.status_code < 300:
                        logger.info(f"Stored workflow result in Supabase: {workflow_id}")
                        supabase_success = True
                    else:
                        logger.warning(f"Failed to store in Supabase: {response.status_code} {response.text}")
            except Exception as e:
                logger.error(f"Error storing workflow result in Supabase: {str(e)}")
        
        # Fall back to file storage if configured or Supabase failed
        if FILE_FALLBACK and (not USE_SUPABASE or not supabase_success):
            try:
                # Determine the appropriate directory
                base_dir = NICHE_SCOUT_DIR if workflow_type == "niche-scout" else BLUEPRINT_DIR
                file_path = f"{base_dir}/{workflow_id}.json"
                
                # Ensure directory exists
                os.makedirs(os.path.dirname(file_path), exist_ok=True)
                
                # Write to file
                with open(file_path, 'w') as f:
                    json.dump(data, f, indent=2)
                    
                logger.info(f"Stored workflow result in file: {file_path}")
            except Exception as e:
                logger.error(f"Error storing workflow result in file: {str(e)}")
                # If both storage methods failed, raise the exception
                if not supabase_success:
                    raise
                    
        return workflow_id
    
    @staticmethod
    async def get_workflow_result(workflow_id: str, workflow_type: str = "niche-scout") -> Optional[Dict[str, Any]]:
        """
        Retrieve a workflow result with hybrid retrieval strategy.
        
        Args:
            workflow_id: The workflow ID
            workflow_type: Type of workflow (niche-scout or seed-to-blueprint)
            
        Returns:
            The workflow data or None if not found
        """
        result = None
        
        # First try Supabase if enabled
        if USE_SUPABASE:
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.get(
                        f"{SUPABASE_URL}/rest/v1/{SOCIAL_OUT_TABLE}",
                        headers={
                            "apikey": SUPABASE_SERVICE_ROLE_KEY,
                            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                            "Content-Type": "application/json"
                        },
                        params={
                            "id": f"eq.{workflow_id}",
                            "select": "*"
                        }
                    )
                    
                    if response.status_code < 300:
                        data = response.json()
                        if data and len(data) > 0:
                            # Extract from data field (JSONB column)
                            if "data" in data[0] and isinstance(data[0]["data"], dict):
                                result = data[0]["data"]
                                logger.info(f"Retrieved workflow result from Supabase: {workflow_id}")
                                return result
            except Exception as e:
                logger.error(f"Error retrieving workflow result from Supabase: {str(e)}")
        
        # Fall back to file if Supabase failed or is disabled
        if FILE_FALLBACK:
            try:
                # Determine the appropriate directory
                base_dir = NICHE_SCOUT_DIR if workflow_type == "niche-scout" else BLUEPRINT_DIR
                file_path = f"{base_dir}/{workflow_id}.json"
                
                # Check for exact file match
                if not os.path.exists(file_path):
                    # Try approximate match using glob
                    import glob
                    matching_files = glob.glob(f"{base_dir}/*{workflow_id}*.json")
                    if matching_files:
                        file_path = matching_files[0]
                    else:
                        logger.warning(f"Workflow result not found in files: {workflow_id}")
                        return None
                
                # Read from file
                with open(file_path, 'r') as f:
                    result = json.load(f)
                    
                logger.info(f"Retrieved workflow result from file: {file_path}")
            except Exception as e:
                logger.error(f"Error retrieving workflow result from file: {str(e)}")
                if result is None:
                    # If both retrieval methods failed, return None
                    return None
        
        return result
    
    @staticmethod
    async def get_workflow_history(limit: int = 50) -> List[Dict[str, Any]]:
        """
        Retrieve workflow history with hybrid retrieval strategy.
        
        Args:
            limit: Maximum number of results to return
            
        Returns:
            List of workflow history items
        """
        results = []
        
        # First try Supabase if enabled
        if USE_SUPABASE:
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.get(
                        f"{SUPABASE_URL}/rest/v1/{SOCIAL_OUT_TABLE}",
                        headers={
                            "apikey": SUPABASE_SERVICE_ROLE_KEY,
                            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                            "Content-Type": "application/json"
                        },
                        params={
                            "select": "*",
                            "order": "created_at.desc",
                            "limit": str(limit)
                        }
                    )
                    
                    if response.status_code < 300:
                        data = response.json()
                        if data:
                            for item in data:
                                if "data" in item and isinstance(item["data"], dict):
                                    workflow_data = item["data"]
                                    workflow_type = "niche-scout" if "niche" in workflow_data else "blueprint"
                                    
                                    # Extract common fields
                                    history_item = {
                                        "id": item.get("id"),
                                        "workflow_type": workflow_type,
                                        "run_date": workflow_data.get("timestamp") or workflow_data.get("run_date"),
                                        "status": "completed",
                                        "parameters": {
                                            "query": workflow_data.get("query"),
                                            "category": workflow_data.get("category"),
                                            "subcategory": workflow_data.get("subcategory")
                                        }
                                    }
                                    
                                    results.append(history_item)
                            
                            logger.info(f"Retrieved {len(results)} workflow history items from Supabase")
                            if results:
                                return results
            except Exception as e:
                logger.error(f"Error retrieving workflow history from Supabase: {str(e)}")
        
        # Fall back to file system if Supabase failed or is disabled
        if FILE_FALLBACK:
            try:
                # Use the existing implementation from workflow_endpoints.py
                # This part remains mostly unchanged to ensure compatibility
                base_dirs = [NICHE_SCOUT_DIR, BLUEPRINT_DIR]
                
                # Find all JSON files in result directories
                import glob
                all_files = []
                for base_dir in base_dirs:
                    if os.path.exists(base_dir):
                        all_files.extend(glob.glob(f"{base_dir}/*.json"))
                
                # Sort files by modification time (newest first)
                all_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
                
                # Limit to the requested number of files
                all_files = all_files[:limit]
                
                # Parse each file to extract metadata
                for file_path in all_files:
                    try:
                        workflow_type = "niche-scout" if "niche" in file_path else "blueprint"
                        
                        with open(file_path, 'r') as f:
                            data = json.load(f)
                        
                        # Extract run date
                        run_date = data.get("run_date") or data.get("date")
                        if not run_date:
                            run_date = datetime.fromtimestamp(os.path.getmtime(file_path)).isoformat()
                        
                        # Extract common fields
                        result_id = os.path.basename(file_path).replace(".json", "")
                        
                        results.append({
                            "id": result_id,
                            "workflow_type": workflow_type,
                            "run_date": run_date,
                            "status": "completed",
                            "parameters": {
                                "query": data.get("query"),
                                "category": data.get("category"),
                                "subcategory": data.get("subcategory")
                            }
                        })
                    except Exception as e:
                        logger.error(f"Error processing history file: {file_path}, {str(e)}")
                
                logger.info(f"Retrieved {len(results)} workflow history items from files")
            except Exception as e:
                logger.error(f"Error retrieving workflow history from files: {str(e)}")
                if not results:
                    # If both retrieval methods failed, return empty list
                    return []
        
        return results

# Initialize client
supabase_client = SupabaseClient()

# Ensure directories exist on startup
asyncio.create_task(supabase_client.ensure_directories())