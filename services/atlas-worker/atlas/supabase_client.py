import os
import logging
import json
import asyncio
import httpx
import uuid

# Configure logging
logger = logging.getLogger("atlas.supabase")

# Environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL", "http://localhost:54321")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

async def store_message(message: dict, table: str = "architect_out") -> str:
    """
    Store a message in Supabase

    Args:
        message: The message to store
        table: The table to store the message in (architect_in or architect_out)

    Returns:
        ID of the stored message
    """
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        logger.warning(f"Supabase not configured, skipping message storage in {table}")
        return str(uuid.uuid4())  # Return fake ID

    try:
        # Add ID if not present
        if "id" not in message:
            message["id"] = str(uuid.uuid4())

        # Create a message object with the correct structure
        # The table has a specific structure with an 'id' column and a 'data' JSONB column
        # The 'data' column should contain the entire message
        message_obj = {
            "id": message["id"],
            "data": message
        }

        # Prepare request
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{SUPABASE_URL}/rest/v1/{table}",
                headers={
                    "apikey": SUPABASE_SERVICE_ROLE_KEY,
                    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal"
                },
                json=message_obj
            )

            if response.status_code >= 400:
                logger.error(f"Error storing message in {table}: {response.status_code} {response.text}")
                if response.status_code == 404:
                    logger.error(f"Table '{table}' may not exist. Run ./scripts/setup_supabase.sh to create it.")
            else:
                response.raise_for_status()
                logger.info(f"Stored message in {table} with ID {message['id']}")

            return message["id"]

    except Exception as e:
        logger.error(f"Error storing message in {table}: {str(e)}")
        return message.get("id", str(uuid.uuid4()))

async def get_message(message_id: str, table: str = "architect_out") -> dict:
    """
    Retrieve a message from Supabase

    Args:
        message_id: The message ID
        table: The table to retrieve the message from

    Returns:
        The message or None if not found
    """
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        logger.warning(f"Supabase not configured, cannot retrieve message {message_id}")
        return None

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"{SUPABASE_URL}/rest/v1/{table}",
                headers={
                    "apikey": SUPABASE_SERVICE_ROLE_KEY,
                    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                    "Content-Type": "application/json"
                },
                params={
                    "id": f"eq.{message_id}",
                    "select": "*"
                }
            )

            if response.status_code == 404:
                logger.error(f"Table '{table}' not found. Run ./scripts/setup_supabase.sh to create it.")
                return None

            response.raise_for_status()
            messages = response.json()

            if messages and len(messages) > 0:
                # The data field contains our actual message (JSONB column)
                # Must check that the expected structure exists
                if "data" in messages[0] and isinstance(messages[0]["data"], dict):
                    return messages[0]["data"]
                else:
                    logger.warning(f"Message {message_id} has unexpected structure: {messages[0]}")
                    return messages[0]  # Return whatever we got anyway

            logger.warning(f"Message {message_id} not found in {table}")
            return None

    except Exception as e:
        logger.error(f"Error retrieving message {message_id} from {table}: {str(e)}")
        return None

async def update_message(message_id: str, updates: dict, table: str = "architect_out") -> bool:
    """
    Update a message in Supabase

    Args:
        message_id: The message ID
        updates: The fields to update
        table: The table containing the message

    Returns:
        True if successful, False otherwise
    """
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        logger.warning(f"Supabase not configured, cannot update message {message_id}")
        return False

    try:
        # Get the current message first
        current_message = await get_message(message_id, table)
        if not current_message:
            logger.error(f"Could not find message {message_id} to update")
            return False

        # Update the message with new values
        updated_message = {**current_message, **updates}

        # Create the update object - maintain the correct structure
        # Since we're updating a record where 'data' is a JSONB column
        update_obj = {
            "data": updated_message
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.patch(
                f"{SUPABASE_URL}/rest/v1/{table}",
                headers={
                    "apikey": SUPABASE_SERVICE_ROLE_KEY,
                    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal"
                },
                params={
                    "id": f"eq.{message_id}"
                },
                json=update_obj
            )

            if response.status_code == 404:
                logger.error(f"Table '{table}' not found or message {message_id} doesn't exist")
                return False
            elif response.status_code >= 400:
                logger.error(f"Error updating message: {response.status_code} {response.text}")
                return False

            response.raise_for_status()
            logger.info(f"Updated message {message_id} in {table}")
            return True

    except Exception as e:
        logger.error(f"Error updating message {message_id} in {table}: {str(e)}")
        return False

async def check_connection() -> bool:
    """
    Check if Supabase is reachable and architect tables exist

    Returns:
        True if Supabase is reachable and tables exist, False otherwise
    """
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        logger.warning("Supabase not configured - missing URL or service role key")
        return False

    try:
        # First check general connectivity
        async with httpx.AsyncClient(timeout=5.0) as client:
            # Try to access the architect_out table (more specific than just checking root endpoint)
            response = await client.get(
                f"{SUPABASE_URL}/rest/v1/architect_out",
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
                logger.warning(f"Could not access architect_out table: HTTP {response.status_code}")
                if response.status_code == 404:
                    logger.error("Tables not found. The architect_in and architect_out tables don't exist")
                    logger.info("Run ./scripts/setup_supabase.sh to create the necessary tables")
                elif response.status_code == 401:
                    logger.error("Authentication failed. Check your SUPABASE_SERVICE_ROLE_KEY")
                    logger.info("Ensure the key has correct permissions and is valid")
                elif response.status_code == 403:
                    logger.error("Permission denied. Your service role key may not have access to these tables")
                    logger.info("Run migrations/0002_atlas_auth.sql to set up the correct permissions")
                return False

            # Try a simple write operation to verify full access
            test_id = str(uuid.uuid4())
            test_msg = {
                "id": test_id,
                "data": {"test": "connectivity", "timestamp": time.time()}
            }

            response = await client.post(
                f"{SUPABASE_URL}/rest/v1/architect_out",
                headers={
                    "apikey": SUPABASE_SERVICE_ROLE_KEY,
                    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal"
                },
                json=test_msg
            )

            if response.status_code >= 300:
                logger.warning(f"Write access check failed: HTTP {response.status_code}")
                if response.status_code == 403:
                    logger.error("Permission denied for write access. Check RLS policies.")
                return False

            # Clean up test data
            await client.delete(
                f"{SUPABASE_URL}/rest/v1/architect_out",
                headers={
                    "apikey": SUPABASE_SERVICE_ROLE_KEY,
                    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                    "Content-Type": "application/json"
                },
                params={
                    "id": f"eq.{test_id}"
                }
            )

            logger.info("Successfully connected to Supabase and verified read/write access")
            return True

    except Exception as e:
        logger.error(f"Error connecting to Supabase: {str(e)}")
        if "ConnectionRefused" in str(e) or "Connection refused" in str(e):
            logger.error("Connection refused. Supabase may not be running or the URL is incorrect")
            logger.info(f"Trying to connect to: {SUPABASE_URL}")
        return False