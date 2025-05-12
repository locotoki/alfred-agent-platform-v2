import asyncio, json, os, logging, time
from atlas.bus_client import subscribe, publish
from atlas.rag_client import get_context
from atlas.openai_client import chat
from atlas.supabase_client import store_message, check_connection
from atlas.metrics import run_seconds, atlas_tokens_total, health_status, rag_reachable, openai_reachable, start_metrics_server, update_budget_percent

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("atlas")

# Create a gauge for Supabase connection status
from prometheus_client import Gauge
supabase_reachable = Gauge("atlas_supabase_reachable", "Supabase reachability (1=reachable, 0=unreachable)")

async def health_check_task():
    """Periodically check all external service health"""
    while True:
        # Check RAG health
        try:
            context = get_context("health check")
            rag_reachable.set(1)
        except Exception as e:
            logger.error(f"RAG health check failed: {str(e)}")
            rag_reachable.set(0)

        # Check Supabase health
        try:
            supabase_status = await check_connection()
            supabase_reachable.set(1 if supabase_status else 0)
        except Exception as e:
            logger.error(f"Supabase health check failed: {str(e)}")
            supabase_reachable.set(0)

        # Update overall health status
        if rag_reachable._value.get() == 1 and openai_reachable._value.get() == 1:
            health_status.set(1)
        else:
            health_status.set(0)

        await asyncio.sleep(60)  # Check every minute

async def handle(msg):
    """Handle an incoming architect message"""
    logger.info(f"Processing task: {msg.get('content', '')[:30]}...")

    # Store incoming message in Supabase
    try:
        await store_message(msg, "architect_in")
    except Exception as e:
        logger.warning(f"Failed to store incoming message in Supabase: {str(e)}")

    try:
        with run_seconds.time():
            processing_start = time.time()

            # Update status to "processing"
            in_progress_msg = {
                **msg,
                "msg_type": "spec",
                "content": "Processing request...",
                "metadata": {
                    **msg.get("metadata", {}),
                    "status": "in_progress",
                    "start_time": processing_start
                }
            }
            await publish(in_progress_msg)

            # Get context from RAG
            try:
                ctx = get_context(msg["content"])
                logger.info(f"Retrieved {len(ctx)} context chunks")
            except Exception as e:
                logger.error(f"RAG error: {str(e)}")
                ctx = []  # Empty context as fallback

            # Get response from OpenAI
            reply = await chat(msg["content"], ctx)

            # Calculate processing time
            processing_time = time.time() - processing_start

            # Prepare output message
            out = {
                **msg,
                "msg_type": "spec",
                "content": reply,
                "metadata": {
                    **msg.get("metadata", {}),
                    "status": "done",
                    "start_time": processing_start,
                    "end_time": time.time(),
                    "processing_time": processing_time
                }
            }

            # Store in Supabase first (for persistence)
            try:
                await store_message(out, "architect_out")
            except Exception as e:
                logger.warning(f"Failed to store output message in Supabase: {str(e)}")

            # Publish the response to the bus
            await publish(out)

            # Update token budget percentage
            update_budget_percent()

            logger.info(f"Task completed successfully in {processing_time:.2f}s")
    except Exception as e:
        logger.error(f"Error processing task: {str(e)}")

        # Send error message
        error_msg = {
            **msg,
            "msg_type": "spec",
            "content": f"Error processing request: {str(e)}",
            "metadata": {
                **msg.get("metadata", {}),
                "status": "error",
                "error": str(e),
                "timestamp": time.time()
            }
        }

        # Store error in Supabase
        try:
            await store_message(error_msg, "architect_out")
        except Exception as store_error:
            logger.warning(f"Failed to store error message in Supabase: {str(store_error)}")

        # Publish error to the bus
        await publish(error_msg)

async def main():
    """Main entry point for Atlas worker"""
    logger.info("Starting Atlas worker...")

    # Start metrics server
    start_metrics_server()
    logger.info("Metrics server started on port 8000")

    # Start health check task
    asyncio.create_task(health_check_task())
    logger.info("Health check task started")

    # Check Supabase connection
    supabase_status = await check_connection()
    if supabase_status:
        logger.info("✅ Successfully connected to Supabase with full read/write access")
        supabase_reachable.set(1)
    else:
        logger.warning("⚠️ Could not establish proper connection to Supabase")
        logger.info("Atlas will run with limited persistence (no message history). For full functionality, verify:")
        logger.info("1. Supabase is running: docker ps | grep supabase")
        logger.info("2. SERVICE_ROLE_KEY is correctly set in .env or .env.dev")
        logger.info("3. Tables exist: run ./scripts/setup_supabase.sh")
        logger.info("4. RLS policies are set up: verify migrations/0002_atlas_auth.sql was applied")
        logger.info("5. Network connectivity: check that atlas-worker can reach supabase-rest in Docker network")
        supabase_reachable.set(0)

    # Subscribe to messages
    logger.info("Subscribing to architect messages...")
    async for raw in subscribe(role="architect"):
        try:
            msg = json.loads(raw.data)
            # Handle each message in a task to allow concurrent processing
            task = asyncio.create_task(handle(msg))

            # Set up done callback to handle success/failure
            def done_callback(future):
                try:
                    future.result()  # This will raise any exceptions from the task
                    raw.ack()  # Acknowledge successful processing
                except Exception as e:
                    logger.error(f"Task failed, not acknowledging: {str(e)}")
                    # Don't ack, let the message be redelivered

            task.add_done_callback(done_callback)

        except json.JSONDecodeError:
            logger.error(f"Invalid JSON in message: {raw.data}")
            raw.ack()  # Acknowledge to prevent infinite retries
        except Exception as e:
            logger.error(f"Error processing message: {str(e)}")
            # Don't ack, let the message be redelivered

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Shutting down gracefully...")
    except Exception as e:
        logger.error(f"Fatal error: {str(e)}")
        health_status.set(0)  # Mark as unhealthy
    finally:
        logger.info("Atlas worker stopped")