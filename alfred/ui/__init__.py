"""User-interface layer (Mission-Control, Streamlit chat, Auth UI).

Legacy import shims — **TO BE REMOVED 2025-07-01**.
"""
import importlib
import sys

for _old, _new in {
    "services.ui.streamlit_chat": "alfred.ui.streamlit_chat",
}.items():
    sys.modules[_old] = importlib.import_module(_new)
