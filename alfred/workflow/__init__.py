"""Workflow engines (crewAI, n8n, pubsub)

Legacy shims — REMOVE BY 2025-07-01
"""
import importlib
import sys

for _o,_n in {
    "services.workflow.crew_ai": "alfred.workflow.crew_ai",
    "services.workflow.n8n":     "alfred.workflow.n8n",
    "services.workflow.pubsub":  "alfred.workflow.pubsub",
}.items():
    sys.modules[_o]=importlib.import_module(_n)
