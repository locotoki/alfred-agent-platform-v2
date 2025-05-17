"""Unit tests for alert grouping functionality."""

import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock

from alfred.alerts.grouping import AlertGroupingService


class TestAlertGrouping:
    """Test alert grouping service."""
    
    @pytest.fixture
    def grouping_service(self):
        """Create a grouping service instance."""
        return AlertGroupingService(
            time_window=timedelta(minutes=15),
            similarity_threshold=0.5
        )
    
    @pytest.fixture
    def sample_alerts(self):
        """Create sample alerts for testing."""
        base_time = datetime.utcnow()
        
        # Similar alerts (same service, similar labels)
        alert1 = Mock()
        alert1.alert_name = "HighCPU"
        alert1.severity = "warning"
        alert1.labels = {"service": "api-gateway", "env": "prod"}
        alert1.fired_at = base_time
        
        alert2 = Mock()
        alert2.alert_name = "HighCPU"
        alert2.severity = "warning"
        alert2.labels = {"service": "api-gateway", "env": "prod", "region": "us-east"}
        alert2.fired_at = base_time + timedelta(minutes=5)
        
        # Different alert (different service)
        alert3 = Mock()
        alert3.alert_name = "HighMemory"
        alert3.severity = "critical"
        alert3.labels = {"service": "database", "env": "prod"}
        alert3.fired_at = base_time + timedelta(minutes=10)
        
        # Alert outside time window
        alert4 = Mock()
        alert4.alert_name = "HighCPU"
        alert4.severity = "warning"
        alert4.labels = {"service": "api-gateway", "env": "prod"}
        alert4.fired_at = base_time + timedelta(minutes=30)
        
        return [alert1, alert2, alert3, alert4]
    
    def test_group_key_generation(self, grouping_service):
        """Test group key generation."""
        alert = Mock()
        alert.alert_name = "HighCPU"
        alert.severity = "warning"
        alert.labels = {"service": "api-gateway"}
        
        key = grouping_service.group_key(alert)
        assert key == "api-gateway:HighCPU:warning"
    
    def test_calculate_hash(self, grouping_service):
        """Test alert hash calculation."""
        alert = Mock()
        alert.alert_name = "HighCPU"
        alert.labels = {"service": "api", "env": "prod"}
        
        hash1 = grouping_service.calculate_hash(alert)
        assert isinstance(hash1, str)
        assert len(hash1) == 32  # MD5 hash length
        
        # Same alert should produce same hash
        hash2 = grouping_service.calculate_hash(alert)
        assert hash1 == hash2
    
    @pytest.mark.parametrize("labels1,labels2,expected_min", [
        (
            {"service": "api", "env": "prod"},
            {"service": "api", "env": "prod"},
            0.9  # Same labels + same name + same severity
        ),
        (
            {"service": "api", "env": "prod"},
            {"service": "api", "env": "prod", "region": "us"},
            0.7  # High overlap
        ),
        (
            {"service": "api"},
            {"service": "database"},
            0.0  # Different service
        ),
    ])
    def test_calculate_similarity(self, grouping_service, labels1, labels2, expected_min):
        """Test similarity calculation with different label sets."""
        alert1 = Mock()
        alert1.alert_name = "HighCPU"
        alert1.severity = "warning"
        alert1.labels = labels1
        
        alert2 = Mock()
        alert2.alert_name = "HighCPU"
        alert2.severity = "warning"
        alert2.labels = labels2
        
        similarity = grouping_service.calculate_similarity(alert1, alert2)
        assert similarity >= expected_min
    
    def test_group_alerts(self, grouping_service, sample_alerts):
        """Test alert grouping functionality."""
        groups = grouping_service.group_alerts(sample_alerts)
        
        # Should have 3 groups:
        # 1. First two HighCPU alerts (similar, within time window)
        # 2. HighMemory alert (different service)
        # 3. Last HighCPU alert (outside time window)
        assert len(groups) == 3
        
        # Check group details
        cpu_group = next(g for g in groups if "api-gateway:HighCPU" in g.group_key)
        assert cpu_group.alert_count == 2
        
        memory_group = next(g for g in groups if "database:HighMemory" in g.group_key)
        assert memory_group.alert_count == 1
    
    def test_cluster_method(self, grouping_service, sample_alerts):
        """Test alternative clustering method."""
        clusters = grouping_service.cluster(sample_alerts)
        
        # Should have 2 main clusters by service
        assert len(clusters) >= 2
        
        # API gateway cluster should have multiple alerts
        api_key = "api-gateway:HighCPU:warning"
        assert api_key in clusters
        assert len(clusters[api_key]) >= 2