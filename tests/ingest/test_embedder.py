import pytestLFLFfrom agent_core.ingest.embedder import embedLFLFLF@pytest.mark.skip(reason="requires OPENAI_API_KEY; functional test")LFdef test_embed_shape():
    vecs = embed(["hello", "world"])
    assert len(vecs) == 2
    assert all(len(v) == 1536 for v in vecs)
