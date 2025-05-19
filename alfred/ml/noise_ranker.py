"""
ML-based noise ranking for alerts.

This module implements a machine learning model to rank alerts
by their "noise" probability, helping to reduce alert fatigue.
"""

from dataclasses import dataclass
from typing import Dict, List, Tuple

import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler

from alfred.core.protocols import AlertProtocol


@dataclass
class NoiseRankingModel:
    """ML model for ranking alert noise levels."""

    def __init__(self, model_path: str = None):
        """Initialize the noise ranking model.

        Args:
            model_path: Path to pre-trained model file
        """
        self.model = None
        self.scaler = StandardScaler()
        self.feature_names = [
            "frequency_24h",
            "frequency_7d",
            "resolution_time_avg",
            "false_positive_rate",
            "severity_score",
            "service_criticality",
            "time_of_day",
            "day_of_week",
        ]

        if model_path:
            self.load_model(model_path)

    def extract_features(self, alert: AlertProtocol, historical_data: Dict) -> np.ndarray:
        """Extract features from an alert for ML prediction.

        Args:
            alert: Alert to extract features from
            historical_data: Historical metrics for the alert type

        Returns:
            Feature vector for the alert
        """
        features = []

        # Frequency features
        features.append(historical_data.get("frequency_24h", 0))
        features.append(historical_data.get("frequency_7d", 0))

        # Resolution time
        features.append(historical_data.get("resolution_time_avg", 0))

        # False positive rate
        features.append(historical_data.get("false_positive_rate", 0))

        # Severity mapping
        severity_map = {"critical": 4, "warning": 3, "info": 2, "debug": 1}
        features.append(severity_map.get(alert.severity, 2))

        # Service criticality (would be looked up from config)
        features.append(historical_data.get("service_criticality", 3))

        # Time features
        import datetime

        now = datetime.datetime.now()
        features.append(now.hour)
        features.append(now.weekday())

        return np.array(features).reshape(1, -1)

    def predict_noise_score(self, alert: AlertProtocol, historical_data: Dict) -> float:
        """Predict noise score for an alert (0-1, higher = more noise).

        Args:
            alert: Alert to score
            historical_data: Historical context

        Returns:
            Noise score between 0 and 1
        """
        if not self.model:
            raise ValueError("Model not loaded. Train or load a model first.")

        features = self.extract_features(alert, historical_data)
        features_scaled = self.scaler.transform(features)

        # Get probability of being noise
        noise_probability = self.model.predict_proba(features_scaled)[0][1]

        return noise_probability

    def rank_alerts(
        self, alerts: List[Tuple[AlertProtocol, Dict]]
    ) -> List[Tuple[AlertProtocol, float]]:
        """Rank a list of alerts by noise score.

        Args:
            alerts: List of (alert, historical_data) tuples

        Returns:
            List of (alert, noise_score) tuples, sorted by score descending
        """
        ranked = []

        for alert, historical_data in alerts:
            score = self.predict_noise_score(alert, historical_data)
            ranked.append((alert, score))

        # Sort by noise score descending (noisiest first)
        ranked.sort(key=lambda x: x[1], reverse=True)

        return ranked

    def train(self, training_data: List[Dict], labels: List[int]):
        """Train the noise ranking model.

        Args:
            training_data: List of feature dictionaries
            labels: List of labels (0=signal, 1=noise)
        """
        # Convert to feature matrix
        X = []
        for data in training_data:
            features = [data.get(name, 0) for name in self.feature_names]
            X.append(features)

        X = np.array(X)
        y = np.array(labels)

        # Scale features
        X_scaled = self.scaler.fit_transform(X)

        # Train model
        self.model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
        self.model.fit(X_scaled, y)

    def save_model(self, path: str):
        """Save trained model to disk."""
        if not self.model:
            raise ValueError("No model to save. Train a model first.")

        joblib.dump(
            {"model": self.model, "scaler": self.scaler, "feature_names": self.feature_names}, path
        )

    def load_model(self, path: str):
        """Load model from disk."""
        data = joblib.load(path)
        self.model = data["model"]
        self.scaler = data["scaler"]
        self.feature_names = data["feature_names"]
