def test_schedule_stub():
    from alfred.ml import retrain_pipeline
    assert callable(retrain_pipeline.schedule)