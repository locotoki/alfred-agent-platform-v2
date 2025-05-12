import os, asyncio, json, logging
from google.cloud import pubsub_v1
from google.api_core.exceptions import AlreadyExists

logger = logging.getLogger("atlas.bus")

# Environment configuration
PROJECT = os.getenv("PUBSUB_PROJECT_ID", "atlas-dev")
TOPIC_OUT = os.getenv("PUBSUB_TOPIC_OUT", "architect_out")
TOPIC_IN = os.getenv("PUBSUB_TOPIC_IN", "architect_in")
SUBSCRIPTION = f"{TOPIC_IN}-sub"

# Clients
publisher = pubsub_v1.PublisherClient()
subscriber = pubsub_v1.SubscriberClient()

def ensure_topic_exists(topic_name):
    """Ensure the topic exists, creating it if necessary"""
    topic_path = publisher.topic_path(PROJECT, topic_name)
    try:
        publisher.create_topic(request={"name": topic_path})
        logger.info(f"Created topic: {topic_path}")
    except AlreadyExists:
        logger.info(f"Topic already exists: {topic_path}")
    return topic_path

def ensure_subscription_exists(topic_path, subscription_name):
    """Ensure the subscription exists, creating it if necessary"""
    subscription_path = subscriber.subscription_path(PROJECT, subscription_name)
    try:
        subscriber.create_subscription(
            request={"name": subscription_path, "topic": topic_path}
        )
        logger.info(f"Created subscription: {subscription_path}")
    except AlreadyExists:
        logger.info(f"Subscription already exists: {subscription_path}")
    return subscription_path

async def publish(msg: dict):
    """Publish a message to the output topic"""
    try:
        # Ensure topic exists
        topic_path = ensure_topic_exists(TOPIC_OUT)

        # Prepare and publish message
        data = json.dumps(msg).encode("utf-8")
        future = publisher.publish(topic_path, data)

        # Wait for publish confirmation
        message_id = await asyncio.wrap_future(future)
        logger.debug(f"Published message with ID: {message_id}")
        return message_id
    except Exception as e:
        logger.error(f"Error publishing message: {str(e)}")
        raise

async def subscribe(role: str):
    """Subscribe to messages for a specific role"""
    # Ensure topic and subscription exist
    topic_path = ensure_topic_exists(TOPIC_IN)
    subscription_path = ensure_subscription_exists(topic_path, SUBSCRIPTION)

    # Create message queue
    flow = asyncio.Queue()

    def _callback(message):
        """Callback for incoming messages"""
        # Don't ack here - we'll ack after processing
        flow.put_nowait(message)

    # Start subscription
    future = subscriber.subscribe(subscription_path, callback=_callback)
    logger.info(f"Subscribed to {subscription_path} for role '{role}'")

    # Monitor subscription in background
    async def _monitor_subscription():
        try:
            await asyncio.wrap_future(future)
        except Exception as e:
            logger.error(f"Subscription error: {str(e)}")
            # Attempt to restart subscription
            await asyncio.sleep(5)
            subscriber.subscribe(subscription_path, callback=_callback)

    asyncio.create_task(_monitor_subscription())

    # Yield messages from queue
    while True:
        message = await flow.get()
        yield message