import datetime
import pathlib
import re
import subprocess

import yaml

PLAN_FILE = pathlib.Path("planning/architect-plan.md")
QUEUE_FILE = pathlib.Path("task-queue.md")


def next_id():
    ids = re.findall(r"\|\s*\[\s*[x ]\s*\]\s*\|\s*(\d+)\s*\|", PLAN_FILE.read_text())
    return max(map(int, ids or [0])) + 1


def parse_tasks(prd_path: pathlib.Path):
    txt = prd_path.read_text()
    m = re.search(r"## Acceptance Tasks\n([\s\S]+)", txt)
    if not m:
        return []
    return [line.strip("- ").strip() for line in m.group(1).splitlines() if line.startswith("- ")]


def append_tasks(tasks, prd_id):
    plan = PLAN_FILE.read_text()
    queue = QUEUE_FILE.read_text()
    for t in tasks:
        tid = next_id()
        row = f"| [ ] | {tid} | {t} | {prd_id} |"
        plan += f"\n{row}"
        queue += f"\n{row}"
    PLAN_FILE.write_text(plan)
    QUEUE_FILE.write_text(queue)


def commit_and_push(branch_name):
    subprocess.run(["git", "checkout", "-b", branch_name])
    subprocess.run(["git", "add", str(PLAN_FILE), str(QUEUE_FILE)])
    msg = f"chore: add tasks via Planner on {datetime.date.today()}"
    subprocess.run(["git", "commit", "-m", msg])
    subprocess.run(["git", "push", "-u", "origin", branch_name])


def main(prd_path_str):
    prd_path = pathlib.Path(prd_path_str)
    prd_id = yaml.safe_load(prd_path.read_text().split("---")[1])["id"]
    tasks = parse_tasks(prd_path)
    if not tasks:
        print("No tasks found.")
        return
    append_tasks(tasks, prd_id)
    commit_and_push(f"planner/tasks-{prd_id.lower()}")


if __name__ == "__main__":
    import sys

    main(sys.argv[1])
