"""
Enhanced alert grouping with advanced heuristics.

Sprint 2 enhancement with Levenshtein distance and contextual similarity.
"""

from typing import List, Dict, Set, Tuple
import Levenshtein
from alfred.core.protocols import AlertProtocol
from alfred.alerts.grouping import AlertGroupingService


class EnhancedAlertGroupingService(AlertGroupingService):
    """Enhanced grouping with multi-factor similarity."""
    
    def __init__(self, similarity_threshold: float = 0.7):
        super().__init__(similarity_threshold)
        self.weights = {
            'jaccard': 0.4,
            'levenshtein': 0.3,
            'context': 0.3
        }
    
    def calculate_similarity(self, alert1: AlertProtocol, alert2: AlertProtocol) -> float:
        """Calculate weighted similarity score."""
        # Jaccard similarity on labels
        jaccard_score = self._jaccard_similarity(alert1, alert2)
        
        # Levenshtein distance on alert names
        levenshtein_score = self._levenshtein_similarity(
            alert1.name, 
            alert2.name
        )
        
        # Contextual similarity (service, environment, region)
        context_score = self._context_similarity(alert1, alert2)
        
        # Weighted combination
        final_score = (
            self.weights['jaccard'] * jaccard_score +
            self.weights['levenshtein'] * levenshtein_score +
            self.weights['context'] * context_score
        )
        
        return final_score
    
    def _levenshtein_similarity(self, str1: str, str2: str) -> float:
        """Calculate Levenshtein similarity between strings."""
        distance = Levenshtein.distance(str1, str2)
        max_len = max(len(str1), len(str2))
        if max_len == 0:
            return 1.0
        return 1.0 - (distance / max_len)
    
    def _context_similarity(self, alert1: AlertProtocol, alert2: AlertProtocol) -> float:
        """Calculate contextual similarity based on alert metadata."""
        context_fields = ['service', 'environment', 'region']
        matches = 0
        total = 0
        
        for field in context_fields:
            if hasattr(alert1, field) and hasattr(alert2, field):
                total += 1
                if getattr(alert1, field) == getattr(alert2, field):
                    matches += 1
        
        return matches / total if total > 0 else 0.0
    
    def auto_merge_suggestions(self, groups: List[Dict]) -> List[Tuple[str, str]]:
        """Suggest groups that should be merged based on high similarity."""
        suggestions = []
        
        for i, group1 in enumerate(groups):
            for group2 in groups[i+1:]:
                similarity = self._group_similarity(group1, group2)
                if similarity > 0.85:  # High confidence threshold
                    suggestions.append((group1['id'], group2['id']))
        
        return suggestions