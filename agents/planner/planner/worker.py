import json, asyncio, os, subprocess
from nats.aio.client import Client as NATS

async def run():
    nc = NATS()
    await nc.connect(os.getenv("NATS_URL", "nats://localhost:4222"))
    async def handler(msg):
        data = json.loads(msg.data.decode())
        prd_path = data["path"]  # path to merged PRD
        subprocess.run(["python","-m","planner.planner_prd",prd_path])
    await nc.subscribe("prd.merged", cb=handler)
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(run())