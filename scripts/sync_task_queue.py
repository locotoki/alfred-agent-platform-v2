#!/usr/bin/env python3
"""Sync task-queue.md with architect-plan.md status"""
import pathlib
import re

def sync_task_queue():
    plan = pathlib.Path('planning/architect-plan.md').read_text()
    queue_f = pathlib.Path('task-queue.md')
    queue = queue_f.read_text()
    row = re.compile(r'\|\s*\[([ xX])\]\s*\|\s*(\d+)\s*\|')

    # Extract task status from plan
    plan_state = {}
    for m in row.finditer(plan):
        task_id = m.group(2)
        status = m.group(1)
        plan_state[task_id] = status

    print(f'Found {len(plan_state)} tasks in architect plan')

    # Update queue status based on plan
    def update_status(match):
        task_id = match.group(2)
        current_status = match.group(1)
        plan_status = plan_state.get(task_id, ' ')
        new_status = 'x' if plan_status == 'x' else ' '
        return f'| [{new_status}] | {task_id} |'

    queue_out = row.sub(update_status, queue)

    if queue_out != queue:
        queue_f.write_text(queue_out)
        print('🔄 task-queue.md synced.')
        return True
    else:
        print('✅ task-queue.md already in sync.')
        return False

if __name__ == "__main__":
    sync_task_queue()