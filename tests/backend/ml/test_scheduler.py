"""Tests for ML model retrain scheduler."""

import unittest
from datetime import datetime
from unittest.mock import MagicMock, Mock, patch

import pytest
import ray
from apscheduler.triggers.cron import CronTrigger
from backend.alfred.ml.retrain_scheduler import RetrainScheduler
from ray import tune


class TestRetrainScheduler(unittest.TestCase):
    """Test cases for RetrainScheduler."""

    def setUp(self):
        """Set up test fixtures."""
        self.scheduler = RetrainScheduler(
            cron_expression="0 2 * * 1", num_samples=2, max_concurrent_trials=1
        )

    def tearDown(self):
        """Clean up after tests."""
        if ray.is_initialized():
            ray.shutdown()

    def test_init(self):
        """Test scheduler initialization."""
        assert self.scheduler.cron_expression == "0 2 * * 1"
        assert self.scheduler.num_samples == 2
        assert self.scheduler.max_concurrent_trials == 1
        assert self.scheduler._last_run is None

    @patch("ray.init")
    def test_start(self, mock_ray_init):
        """Test scheduler start."""
        with patch.object(self.scheduler.scheduler, "add_job") as mock_add_job:
            with patch.object(self.scheduler.scheduler, "start") as mock_start:
                self.scheduler.start()

                mock_ray_init.assert_called_once_with(address=None)
                mock_add_job.assert_called_once()
                mock_start.assert_called_once()

                # Verify job configuration
                call_args = mock_add_job.call_args
                assert call_args.kwargs["id"] == "ml_retrain_job"
                assert call_args.kwargs["name"] == "Weekly ML Model Retraining"
                assert isinstance(call_args.kwargs["trigger"], CronTrigger)

    @patch("ray.shutdown")
    @patch("ray.is_initialized", return_value=True)
    def test_stop(self, mock_is_initialized, mock_ray_shutdown):
        """Test scheduler stop."""
        with patch.object(self.scheduler.scheduler, "shutdown") as mock_shutdown:
            self.scheduler.stop()

            mock_shutdown.assert_called_once()
            mock_ray_shutdown.assert_called_once()

    @patch("ray.tune.report")
    def test_train_fn(self, mock_report):
        """Test training function."""
        config = {
            "batch_size": 32,
            "learning_rate": 0.001,
            "hidden_size": 256,
            "num_epochs": 20,
            "dropout_rate": 0.3,
            "temperature": 1.0,
        }

        metrics = self.scheduler._train_fn(config)

        assert "validation_loss" in metrics
        assert "noise_reduction" in metrics
        assert "latency_p95" in metrics

        mock_report.assert_called_once_with(**metrics)

    @patch("backend.alfred.ml.retrain_scheduler.logger")
    def test_update_production_models(self, mock_logger):
        """Test production model update."""
        best_config = {"learning_rate": 0.001, "hidden_size": 256}

        self.scheduler._update_production_models(best_config)

        mock_logger.info.assert_called_once_with(
            f"Updating production models with config: {best_config}"
        )

    @patch("backend.alfred.ml.retrain_scheduler.Tuner")
    @patch("ray.tune.with_resources")
    @patch("backend.alfred.ml.retrain_scheduler.ASHAScheduler")
    def test_retrain_models(self, mock_asha, mock_with_resources, mock_tuner):
        """Test model retraining execution."""
        # Mock Ray Tune components
        mock_results = Mock()
        mock_best_result = Mock()
        mock_best_result.config = {"learning_rate": 0.001}
        mock_best_result.metrics = {"validation_loss": 0.15}
        mock_results.get_best_result.return_value = mock_best_result

        mock_tuner_instance = Mock()
        mock_tuner_instance.fit.return_value = mock_results
        mock_tuner.return_value = mock_tuner_instance

        with patch.object(self.scheduler, "_update_production_models") as mock_update:
            self.scheduler._retrain_models()

            # Verify last run was updated
            assert self.scheduler._last_run is not None
            assert isinstance(self.scheduler._last_run, datetime)

            # Verify Ray Tune was called correctly
            mock_asha.assert_called_once()
            mock_with_resources.assert_called_once()
            mock_tuner.assert_called_once()
            mock_tuner_instance.fit.assert_called_once()

            # Verify production models were updated
            mock_update.assert_called_once_with(mock_best_result.config)

    @patch("backend.alfred.ml.retrain_scheduler.logger")
    @patch("backend.alfred.ml.retrain_scheduler.Tuner")
    def test_retrain_models_error(self, mock_tuner, mock_logger):
        """Test error handling during retraining."""
        # Mock an error during tuning
        mock_tuner.side_effect = Exception("Training failed")

        with pytest.raises(Exception, match="Training failed"):
            self.scheduler._retrain_models()

        mock_logger.error.assert_called_once()

    def test_last_run_property(self):
        """Test last_run property."""
        assert self.scheduler.last_run is None

        test_time = datetime.now()
        self.scheduler._last_run = test_time

        assert self.scheduler.last_run == test_time

    def test_custom_cron_expression(self):
        """Test custom cron expression."""
        custom_scheduler = RetrainScheduler(cron_expression="0 0 * * *")
        assert custom_scheduler.cron_expression == "0 0 * * *"

    def test_ray_address_configuration(self):
        """Test Ray address configuration."""
        ray_scheduler = RetrainScheduler(ray_address="ray://cluster:10001")
        assert ray_scheduler.ray_address == "ray://cluster:10001"


if __name__ == "__main__":
    unittest.main()
