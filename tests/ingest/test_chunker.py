from agent_core.ingest.chunker import chunkLFLFLFdef test_chunker_basic():LF    txt = "word " * 3000
    chunks = chunk(txt)
    assert len(chunks) > 1
    assert all(chunks)
