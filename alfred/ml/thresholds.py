"""Dynamic threshold optimization service for ML noise reduction"""

import json
from dataclasses import dataclass
from typing import Dict, Optional

from alfred.core.protocols import Service
from alfred.metrics.protocols import MetricsCollector


@dataclass
class ThresholdConfig:
    """Configuration for dynamic thresholds"""

    noise_threshold: float = 0.7
    confidence_min: float = 0.85
    batch_size: int = 100
    learning_rate: float = 0.01

    def to_dict(self) -> Dict[str, float]:
        """Convert to dictionary representation"""
        return {
            "noise_threshold": self.noise_threshold,
            "confidence_min": self.confidence_min,
            "batch_size": self.batch_size,
            "learning_rate": self.learning_rate,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, float]) -> "ThresholdConfig":
        """Create from dictionary representation"""
        return cls(**data)


class ThresholdService(Service):
    """Service for managing dynamic ML thresholds.

    This service allows runtime adjustment of ML model thresholds based on performance
    metrics and operator feedback.
    """

    def __init__(
        self,
        metrics: Optional[MetricsCollector] = None,
        config_path: str = "/etc/alfred/thresholds.json",
    ):
        """Initialize the threshold service.

        Args:
            metrics: Optional metrics collector
            config_path: Path to persistent config file.
        """
        self.metrics = metrics
        self.config_path = config_path
        self._config = self._load_config()

    def _load_config(self) -> ThresholdConfig:
        """Load configuration from disk or use defaults"""
        try:
            with open(self.config_path, "r") as f:
                data = json.load(f)
                return ThresholdConfig.from_dict(data)
        except (FileNotFoundError, json.JSONDecodeError):
            return ThresholdConfig()

    def _save_config(self) -> None:
        """Persist configuration to disk"""
        try:
            with open(self.config_path, "w") as f:
                json.dump(self._config.to_dict(), f, indent=2)
        except Exception as e:
            # Log but don't fail on save errors
            if self.metrics:
                self.metrics.increment("threshold.save_error", {"error": str(e)})

    def get_thresholds(self) -> Dict[str, float]:
        """Get current threshold configuration.

        Returns:
            Dictionary of threshold values.
        """
        return self._config.to_dict()

    def update_thresholds(self, updates: Dict[str, float]) -> Dict[str, float]:
        """Update threshold values.

        Args:
            updates: Dictionary of threshold updates

        Returns:
            Updated threshold configuration.
        """
        # Validate updates
        valid_keys = {
            "noise_threshold",
            "confidence_min",
            "batch_size",
            "learning_rate",
        }
        invalid_keys = set(updates.keys()) - valid_keys
        if invalid_keys:
            raise ValueError(f"Invalid threshold keys: {invalid_keys}")

        # Apply updates
        for key, value in updates.items():
            setattr(self._config, key, value)

        # Save to disk
        self._save_config()

        # Track metrics
        if self.metrics:
            for key, value in updates.items():
                self.metrics.gauge(f"threshold.{key}", value)

        return self._config.to_dict()

    def optimize_thresholds(self, performance_metrics: Dict[str, float]) -> Dict[str, float]:
        """Automatically optimize thresholds based on performance.

        Args:
            performance_metrics: Recent performance data

        Returns:
            Optimized threshold configuration.
        """
        # Simple optimization: adjust noise threshold based on false positive rate
        if "false_positive_rate" in performance_metrics:
            fpr = performance_metrics["false_positive_rate"]
            if fpr > 0.1:  # Too many false positives
                self._config.noise_threshold = min(0.95, self._config.noise_threshold + 0.05)
            elif fpr < 0.05:  # Too conservative
                self._config.noise_threshold = max(0.5, self._config.noise_threshold - 0.02)

        # Adjust confidence based on accuracy
        if "accuracy" in performance_metrics:
            acc = performance_metrics["accuracy"]
            if acc < 0.9:
                self._config.confidence_min = min(0.95, self._config.confidence_min + 0.02)
            elif acc > 0.95:
                self._config.confidence_min = max(0.7, self._config.confidence_min - 0.01)

        self._save_config()
        return self._config.to_dict()
