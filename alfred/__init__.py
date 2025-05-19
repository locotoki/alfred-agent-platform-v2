"""Alfred main namespace package.

Legacy import shims — **TO BE REMOVED 2025-07-01**
Please migrate to `alfred.*` imports and drop `services.`.
"""

__version__ = "0.9.0"

import sys
from importlib import import_module

# Legacy import compatibility shims
for _old, _new in {
    "services.alfred_core": "alfred.core.alfred_core",
    "services.alfred_bot": "alfred.core.alfred_bot",
    "services.api": "alfred.core.api",
    "services.db_storage": "alfred.storage.db_storage",
    "services.db-postgres": "alfred.storage.db_postgres",
    "services.redis": "alfred.storage.redis",
    "services.vector_db": "alfred.storage.vector_db",
}.items():
    try:
        sys.modules[_old] = import_module(_new)
    except ImportError:
        pass  # Module not yet migrated
