import asyncio
import json
import os
import subprocess

from nats.aio.client import Client as NATS


async def run():
    nc = NATS()
    await nc.connect(os.getenv("NATS_URL", "nats://localhost:4222"))

    async def handler(msg):
        data = json.loads(msg.data.decode())
        prd_path = data["path"]  # path to merged PRD
        subprocess.run(["python", "-m", "planner.planner_prd", prd_path])
        await msg.ack()

    js = nc.jetstream()
    await js.add_consumer(stream="EVENTS",
                          config={"durable_name": "planner", "filter_subject": "prd.merged"})
    sub = await js.pull_subscribe("prd.merged", durable="planner")
    
    while True:
        msgs = await sub.fetch(1, timeout=1)
        for msg in msgs:
            await handler(msg)
        await asyncio.sleep(1)


if __name__ == "__main__":
    asyncio.run(run())