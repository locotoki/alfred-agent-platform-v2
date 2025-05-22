"""Script to generate tech debt velocity metrics."""

import csv
import datetime
import pathlib
import subprocess
import sys

csv_path = pathlib.Path("metrics/scripts_inventory.csv")
removed = int(
    subprocess.check_output(["git", "log", "--pretty=format:", "--name-status", "HEAD"], text=True)
    .splitlines()
    .count("D")
)  # crude but good enough
today = datetime.date.today().isoformat()
out = pathlib.Path("metrics/tech_debt_velocity.csv")
rows = []
if out.exists():
    rows = list(csv.DictReader(out.open()))
cumulative = int(rows[-1]["cumulative"]) if rows else 0
rows.append({"date": today, "scripts_removed": removed, "cumulative": cumulative + removed})
with out.open("w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["date", "scripts_removed", "cumulative"])
    w.writeheader()
    w.writerows(rows)
