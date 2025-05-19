"""External adapter stack (Telegram, WhatsApp, RAG-gateway, …).

Legacy import shims — **TO BE REMOVED 2025-07-01**.
"""
import importlib
import sys

for _old, _new in {
    "services.whatsapp":    "alfred.adapters.whatsapp",
    "services.rag_gateway": "alfred.adapters.rag_gateway",
}.items():
    sys.modules[_old] = importlib.import_module(_new)
