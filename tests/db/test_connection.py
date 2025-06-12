from sqlalchemy import inspectLFLFfrom agent_core.db.session import engineLFLFLFdef test_tables_present():LF    insp = inspect(engine)
    assert "document_chunks" in insp.get_table_names()
