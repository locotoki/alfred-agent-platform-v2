"""Unit tests for enhanced alert grouping similarity algorithms."""

import pytest
from unittest.mock import Mock
from backend.alfred.alerts.grouping_v2 import EnhancedAlertGroupingService
from alfred.core.protocols import AlertProtocol


class TestSimilarityAlgorithms:
    """Test suite for alert similarity calculations."""
    
    def test_jaccard_similarity_identical_labels(self):
        """Test Jaccard similarity for identical label sets."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.labels = {'service': 'api', 'env': 'prod'}
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.labels = {'service': 'api', 'env': 'prod'}
        
        score = service._jaccard_similarity(alert1, alert2)
        assert score == 1.0
    
    def test_jaccard_similarity_no_overlap(self):
        """Test Jaccard similarity with no overlapping labels."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.labels = {'service': 'api'}
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.labels = {'app': 'web'}
        
        score = service._jaccard_similarity(alert1, alert2)
        assert score == 0.0
    
    def test_jaccard_similarity_partial_overlap(self):
        """Test Jaccard similarity with partial label overlap."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.labels = {'service': 'api', 'env': 'prod'}
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.labels = {'service': 'api', 'region': 'us-east'}
        
        # Intersection: {('service', 'api')} = 1
        # Union: 3 unique items
        score = service._jaccard_similarity(alert1, alert2)
        assert pytest.approx(score, 0.01) == 1/3
    
    def test_levenshtein_similarity_identical(self):
        """Test Levenshtein similarity for identical strings."""
        service = EnhancedAlertGroupingService()
        
        score = service._levenshtein_similarity("HighCPU", "HighCPU")
        assert score == 1.0
    
    def test_levenshtein_similarity_different(self):
        """Test Levenshtein similarity for different strings."""
        service = EnhancedAlertGroupingService()
        
        score = service._levenshtein_similarity("HighCPU", "LowMem")
        assert score < 0.5
    
    def test_levenshtein_similarity_similar(self):
        """Test Levenshtein similarity for similar strings."""
        service = EnhancedAlertGroupingService()
        
        score = service._levenshtein_similarity("HighCPU", "HighGPU")
        assert 0.5 < score < 1.0
    
    def test_context_similarity_matching(self):
        """Test context similarity with matching fields."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.service = 'api'
        alert1.environment = 'prod'
        alert1.region = 'us-east'
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.service = 'api'
        alert2.environment = 'prod'
        alert2.region = 'us-east'
        
        score = service._context_similarity(alert1, alert2)
        assert score == 1.0
    
    def test_context_similarity_partial_match(self):
        """Test context similarity with partial matches."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.service = 'api'
        alert1.environment = 'prod'
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.service = 'api'
        alert2.environment = 'dev'
        
        score = service._context_similarity(alert1, alert2)
        assert score == 0.5  # 1 match out of 2 fields
    
    def test_weighted_similarity_calculation(self):
        """Test complete weighted similarity calculation."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.name = "HighCPU"
        alert1.labels = {'service': 'api', 'severity': 'high'}
        alert1.service = 'api'
        alert1.environment = 'prod'
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.name = "HighCPU"
        alert2.labels = {'service': 'api', 'severity': 'high'}
        alert2.service = 'api'
        alert2.environment = 'prod'
        
        score = service.calculate_similarity(alert1, alert2)
        assert score == 1.0
    
    def test_group_similarity_with_representatives(self):
        """Test group similarity using representative alerts."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.name = "HighCPU"
        alert1.labels = {'service': 'api'}
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.name = "HighCPU"
        alert2.labels = {'service': 'api'}
        
        group1 = {'id': '1', 'representative_alert': alert1}
        group2 = {'id': '2', 'representative_alert': alert2}
        
        score = service._group_similarity(group1, group2)
        assert score > 0.8
    
    def test_auto_merge_suggestions(self):
        """Test automatic merge suggestions for similar groups."""
        service = EnhancedAlertGroupingService()
        
        alert1 = Mock(spec=AlertProtocol)
        alert1.name = "HighCPU"
        alert1.labels = {'service': 'api'}
        alert1.service = 'api'
        alert1.environment = 'prod'
        
        alert2 = Mock(spec=AlertProtocol)
        alert2.name = "HighCPU"
        alert2.labels = {'service': 'api'}
        alert2.service = 'api'
        alert2.environment = 'prod'
        
        groups = [
            {'id': '1', 'representative_alert': alert1},
            {'id': '2', 'representative_alert': alert2},
            {'id': '3', 'key': 'different:alert:type'}
        ]
        
        suggestions = service.auto_merge_suggestions(groups)
        assert ('1', '2') in suggestions
        assert len(suggestions) == 1  # Only highly similar groups