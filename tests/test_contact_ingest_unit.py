import asyncioLFimport jsonLFimport osLFLFimport httpxLFimport respxLFLFfrom services.contact_ingest.app.main import CRM_SYNC_URL, ingest_loopLFLFLF@respx.mockLFdef test_ingest_loop(tmp_path):
    # prepare fake data file
    data = {
        "email": "unit@example.com",
        "source": "web",
        "timestamp": "2025-05-28T12:00:00Z",
        "payload": {"firstName": "Unit", "lastName": "Test"},
    }
    d = tmp_path / "data"
    d.mkdir()
    f = d / "contacts.jsonl"
    f.write_text(json.dumps(data) + "\n")

    respx.post(CRM_SYNC_URL).mock(return_value=httpx.Response(200, json={}))

    os.environ["INGEST_DIR"] = str(d)
    loop = asyncio.get_event_loop()
    loop.run_until_complete(asyncio.wait_for(ingest_loop(), timeout=6))

    assert respx.calls.call_count >= 1
