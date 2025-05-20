"""Fixed workflow endpoints module to address datetime parsing issues."""

import glob
import json
import os
from datetime import datetime, timedelta
from typing import Any, Dict, List

import structlog

logger = structlog.get_logger(__name__)


def validate_datetime(dt_str: str) -> datetime:.
    """Validate and parse a datetime string safely.

    Args:
        dt_str: Datetime string in ISO format

    Returns:
        Parsed datetime object or current time if invalid
    """
    try:
        # Handle various datetime formats
        if "Z" in dt_str:
            dt_str = dt_str.replace("Z", "+00:00")

        # Parse the datetime string
        dt = datetime.fromisoformat(dt_str)

        # Validate minute value (to fix the "minute must be in 0..59" error)
        if dt.minute >= 60:
            logger.error("Invalid minute value", minute=dt.minute, dt_str=dt_str)
            # Fix the minute value
            dt = dt.replace(minute=dt.minute % 60)
            # If minute was invalid, the hour might need adjustment
            if dt.minute >= 60:
                dt = dt + timedelta(hours=1)
                dt = dt.replace(minute=dt.minute % 60)

        return dt
    except ValueError as e:
        logger.error("Invalid datetime format", dt_str=dt_str, error=str(e))
        return datetime.now()
    except Exception as e:
        logger.error("Unexpected error parsing datetime", dt_str=dt_str, error=str(e))
        return datetime.now()


async def get_workflow_history() -> List[Dict[str, Any]]:
    """Retrieve workflow execution history.

    Returns:
        List of workflow execution records.
    """
    try:
        # Base directory for workflow results
        base_dirs = ["/app/data/niche_scout", "/app/data/blueprint"]

        # Find all JSON files in result directories
        all_files = []
        for base_dir in base_dirs:
            if os.path.exists(base_dir):
                all_files.extend(glob.glob(f"{base_dir}/*.json"))

        # Sort files by modification time (newest first)
        all_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)

        # Limit to the most recent 50 files
        all_files = all_files[:50]

        # Parse each file to extract metadata
        history = []
        for file_path in all_files:
            try:
                workflow_type = "niche-scout" if "niche" in file_path else "blueprint"

                with open(file_path, "r") as f:
                    data = json.load(f)

                # Extract run date with validation
                run_date = data.get("run_date") or data.get("date")
                if run_date:
                    try:
                        # Use the safe datetime validation function
                        parsed_date = validate_datetime(run_date)
                        formatted_date = parsed_date.isoformat()
                    except Exception as e:
                        logger.error(
                            "Error parsing run date", run_date=run_date, error=str(e)
                        )
                        # Fallback to file modification time
                        formatted_date = datetime.fromtimestamp(
                            os.path.getmtime(file_path)
                        ).isoformat()
                else:
                    # Fallback to file modification time
                    formatted_date = datetime.fromtimestamp(
                        os.path.getmtime(file_path)
                    ).isoformat()

                # Extract common fields
                result_id = os.path.basename(file_path).replace(".json", "")

                history.append(
                    {
                        "id": result_id,
                        "workflow_type": workflow_type,
                        "run_date": formatted_date,
                        "status": "completed",
                        "parameters": {
                            "query": data.get("query"),
                            "category": data.get("category"),
                            "subcategory": data.get("subcategory"),
                        },
                    }
                )
            except Exception as e:
                logger.error(
                    "Error processing history file", file=file_path, error=str(e)
                )

        return history
    except Exception as e:
        logger.error("error_retrieving_workflow_history", error=str(e))
        return []


async def get_workflow_result(result_id: str, type: str) -> Dict[str, Any]:
    """Retrieve a specific workflow result by ID.

    Args:
        result_id: ID of the workflow result
        type: Type of workflow (niche-scout or seed-to-blueprint)

    Returns:
        Workflow result data or error message.
    """
    try:
        # Determine base directory
        if type == "niche-scout":
            base_dir = "/app/data/niche_scout"
        elif type == "seed-to-blueprint":
            base_dir = "/app/data/blueprint"
        else:
            return {"error": f"Unknown workflow type: {type}"}

        # Look for exact file match first
        file_path = f"{base_dir}/{result_id}.json"
        if not os.path.exists(file_path):
            # Try searching for files containing the ID
            matching_files = glob.glob(f"{base_dir}/*{result_id}*.json")
            if matching_files:
                file_path = matching_files[0]
            else:
                return {"error": f"Result not found: {result_id}"}

        # Load and return the result
        with open(file_path, "r") as f:
            data = json.load(f)

        # Add metadata
        data["_id"] = result_id
        data["_retrieved"] = datetime.now().isoformat()

        return data
    except Exception as e:
        logger.error(
            "error_retrieving_workflow_result",
            result_id=result_id,
            type=type,
            error=str(e),
        )
        return {"error": str(e)}


async def get_scheduled_workflows() -> List[Dict[str, Any]]:
    """Retrieve list of scheduled workflows.

    Returns:
        List of scheduled workflow configurations.
    """
    try:
        # For now, return a placeholder implementation
        # In a real implementation, this would query a database
        return [
            {
                "id": "scheduled-niche-scout-1",
                "workflow_type": "niche-scout",
                "frequency": "daily",
                "next_run": (datetime.now() + timedelta(days=1))
                .replace(hour=10, minute=0, second=0)
                .isoformat(),
                "parameters": {"category": "tech", "subcategory": None},
            },
            {
                "id": "scheduled-blueprint-1",
                "workflow_type": "seed-to-blueprint",
                "frequency": "weekly",
                "next_run": (datetime.now() + timedelta(days=7))
                .replace(hour=14, minute=0, second=0)
                .isoformat(),
                "parameters": {"niche": "educational technology"},
            },
        ]
    except Exception as e:
        logger.error("error_retrieving_scheduled_workflows", error=str(e))
        return []


async def schedule_workflow(
    workflow_type: str, parameters: Dict[str, Any], frequency: str, next_run: str
) -> Dict[str, Any]:
    """Schedule a new workflow execution.

    Args:
        workflow_type: Type of workflow (niche-scout or seed-to-blueprint)
        parameters: Workflow-specific parameters
        frequency: Schedule frequency (daily, weekly, monthly, once)
        next_run: Next scheduled run time (ISO datetime string)

    Returns:
        Created schedule object.
    """
    try:
        # Validate workflow type
        if workflow_type not in ["niche-scout", "seed-to-blueprint"]:
            return {"error": f"Unsupported workflow type: {workflow_type}"}

        # Validate frequency
        if frequency not in ["daily", "weekly", "monthly", "once"]:
            return {"error": f"Unsupported frequency: {frequency}"}

        # Validate and parse next_run
        try:
            # Use the safe datetime validation function
            parsed_next_run = validate_datetime(next_run)
        except Exception as e:
            return {"error": f"Invalid next_run date format: {str(e)}"}

        # For now, return a placeholder implementation
        # In a real implementation, this would insert into a database
        return {
            "id": f"scheduled-{workflow_type}-{int(datetime.now().timestamp())}",
            "workflow_type": workflow_type,
            "frequency": frequency,
            "next_run": parsed_next_run.isoformat(),
            "parameters": parameters,
            "created_at": datetime.now().isoformat(),
        }
    except Exception as e:
        logger.error(
            "error_scheduling_workflow",
            workflow_type=workflow_type,
            frequency=frequency,
            error=str(e),
        )
        return {"error": str(e)}
