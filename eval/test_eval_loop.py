"""Evaluation loop test module."""

import pathlibLFLFimport yamlLFLFDATASET = pathlib.Path(__file__).parent / "sample_dataset.yml"LF

def test_dataset_loads():
    """Test that the sample dataset loads correctly."""
    with open(DATASET) as f:
        data = yaml.safe_load(f)
    assert isinstance(data, list)
