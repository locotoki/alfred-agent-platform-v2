#!/usr/bin/env python3
"""
Script to set up PubSub topics and subscriptions for the CrewAI service.
"""

import os
import argparse
from google.cloud import pubsub_v1

def setup_pubsub(project_id="alfred-agent-platform", emulator_host=None):
    """Set up PubSub topics and subscriptions for the CrewAI service."""
    if emulator_host:
        os.environ["PUBSUB_EMULATOR_HOST"] = emulator_host
        print(f"Using PubSub emulator at {emulator_host}")
    
    # Initialize clients
    publisher = pubsub_v1.PublisherClient()
    subscriber = pubsub_v1.SubscriberClient()
    
    # Define topics and subscriptions
    topics = [
        "crew.tasks",
        "crew.results"
    ]
    
    subscriptions = [
        ("crew.tasks", "crew-tasks-subscription"),
        ("crew.results", "crew-results-subscription")
    ]
    
    # Create topics
    for topic_name in topics:
        topic_path = publisher.topic_path(project_id, topic_name)
        try:
            topic = publisher.create_topic(request={"name": topic_path})
            print(f"Created topic: {topic.name}")
        except Exception as e:
            if "AlreadyExists" in str(e):
                print(f"Topic already exists: {topic_path}")
            else:
                print(f"Error creating topic {topic_name}: {e}")
    
    # Create subscriptions
    for topic_name, subscription_name in subscriptions:
        topic_path = publisher.topic_path(project_id, topic_name)
        subscription_path = subscriber.subscription_path(project_id, subscription_name)
        try:
            subscription = subscriber.create_subscription(
                request={"name": subscription_path, "topic": topic_path}
            )
            print(f"Created subscription: {subscription.name}")
        except Exception as e:
            if "AlreadyExists" in str(e):
                print(f"Subscription already exists: {subscription_path}")
            else:
                print(f"Error creating subscription {subscription_name}: {e}")
    
    print("PubSub setup complete!")

def main():
    """Main function to run the script."""
    parser = argparse.ArgumentParser(description="Set up PubSub for CrewAI service")
    parser.add_argument(
        "--project-id", 
        default="alfred-agent-platform",
        help="Google Cloud project ID"
    )
    parser.add_argument(
        "--emulator-host",
        default="localhost:8085",
        help="PubSub emulator host address (hostname:port)"
    )
    
    args = parser.parse_args()
    setup_pubsub(args.project_id, args.emulator_host)

if __name__ == "__main__":
    main()