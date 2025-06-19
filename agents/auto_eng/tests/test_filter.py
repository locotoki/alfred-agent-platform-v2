def test_auto_mark():
    from auto_eng.worker import AUTO_MARK

    assert AUTO_MARK in "[auto] simple task"
    assert AUTO_MARK.lower() in "Implement login [auto]"