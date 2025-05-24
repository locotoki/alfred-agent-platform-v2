from agent_core.db.session import engine
from sqlalchemy import inspect


def test_tables_present():
    insp = inspect(engine)
    assert "document_chunks" in insp.get_table_names()
