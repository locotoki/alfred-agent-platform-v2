"""Tests for model registry functions."""
import pytest
from unittest.mock import patch
from backend.alfred.ml.model_registry import should_promote, save_promoted_model

def test_should_promote_good_metrics():
    """Test promotion with metrics above thresholds."""
    metrics = {"noise_cut": 0.46, "fnr": 0.018}
    assert should_promote(metrics) is True

def test_should_promote_low_noise_cut():
    """Test rejection when noise cut is too low."""
    metrics = {"noise_cut": 0.44, "fnr": 0.018}
    assert should_promote(metrics) is False

def test_should_promote_high_fnr():
    """Test rejection when false negative rate is too high."""
    metrics = {"noise_cut": 0.46, "fnr": 0.025}
    assert should_promote(metrics) is False

def test_should_promote_edge_cases():
    """Test edge cases at exact thresholds."""
    # Exactly at noise cut threshold
    metrics = {"noise_cut": 0.45, "fnr": 0.018}
    assert should_promote(metrics) is True
    
    # Exactly at FNR threshold
    metrics = {"noise_cut": 0.46, "fnr": 0.02}
    assert should_promote(metrics) is False

@patch('builtins.print')
def test_save_promoted_model(mock_print):
    """Test model saving (currently prints only)."""
    model_path = "/tmp/model"
    metrics = {"noise_cut": 0.46, "fnr": 0.018}
    
    save_promoted_model(model_path, metrics)
    
    # Verify print statements were called
    assert mock_print.call_count == 2
    mock_print.assert_any_call(f"Model promoted with metrics: {metrics}")
    mock_print.assert_any_call(f"Saving model from: {model_path}")