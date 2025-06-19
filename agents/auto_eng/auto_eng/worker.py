import asyncio
import json
import os
import pathlib
import subprocess
import sys

from github import Github
from nats.aio.client import Client as NATS

GH_TOKEN = os.getenv("GITHUB_TOKEN")
REPO_FULL = os.getenv("GITHUB_REPOSITORY")
AUTO_MARK = "[auto]"


def claim_task(task_id, prd_id, description):
    branch = f"auto/task-{task_id}"
    subprocess.run(["git", "checkout", "-B", branch], check=True)
    todo = pathlib.Path(f"todo/TASK-{task_id}.md")
    todo.parent.mkdir(exist_ok=True)
    todo.write_text(f"# TODO {task_id}\n\n{description}\n")
    subprocess.run(["git", "add", str(todo)])
    subprocess.run(["git", "commit", "-m", f"docs: stub for task {task_id}"], check=True)
    subprocess.run(["git", "push", "-u", "origin", branch], check=True)

    gh = Github(GH_TOKEN)
    repo = gh.get_repo(REPO_FULL)
    pr = repo.create_pull(
        title=f"Auto-claim task {task_id}",
        body=f"prd-id: {prd_id}\ntask-id: {task_id}\n\nAuto-generated stub.",
        head=branch,
        base="main",
        draft=True,
    )
    print("Opened PR", pr.number)


async def main():
    nc = NATS()
    await nc.connect(os.getenv("NATS_URL", "nats://localhost:4222"))

    async def handler(msg):
        data = json.loads(msg.data.decode())
        desc = data["description"]
        if AUTO_MARK not in desc.lower():
            return
        task_id = data["task_id"]
        prd_id = data["prd_id"]
        print("Auto-claiming task", task_id)
        claim_task(task_id, prd_id, desc)

    await nc.subscribe("task.created", durable="autoeng", cb=handler)
    while True:
        await asyncio.sleep(60)


if __name__ == "__main__":
    asyncio.run(main())