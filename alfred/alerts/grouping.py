"""Alert grouping and correlation service.

This module implements the core logic for grouping related alerts
to reduce notification noise and improve incident response.
"""

import hashlib
import logging
from collections import defaultdict
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any, Set
from uuid import UUID

from alfred.core.protocols import AlertProtocol
from alfred.alerts.models.alert_group import AlertGroup

logger = logging.getLogger(__name__)


class AlertGroupingService:
    """Service for grouping and correlating alerts."""
    
    def __init__(self, 
                 time_window: timedelta = timedelta(minutes=15),
                 similarity_threshold: float = 0.5):
        """Initialize alert grouping service.
        
        Args:
            time_window: Time window for grouping related alerts
            similarity_threshold: Minimum similarity score for grouping (0-1)
        """
        self.time_window = time_window
        self.similarity_threshold = similarity_threshold
    
    def group_key(self, alert: AlertProtocol) -> str:
        """Generate grouping key for an alert.
        
        Args:
            alert: Alert to generate key for
            
        Returns:
            Group key string
        """
        # Group by service, alert name, and severity
        key_parts = [
            alert.labels.get('service', 'unknown'),
            alert.alert_name,
            alert.severity
        ]
        return ":".join(key_parts)
    
    def calculate_hash(self, alert: AlertProtocol) -> str:
        """Calculate hash for fast alert lookups.
        
        Args:
            alert: Alert to hash
            
        Returns:
            Hash string
        """
        # Hash based on labels and alert name
        hash_data = f"{alert.alert_name}:{sorted(alert.labels.items())}"
        return hashlib.md5(hash_data.encode()).hexdigest()
    
    def group_alerts(self, alerts: List[AlertProtocol]) -> List[AlertGroup]:
        """Group related alerts based on similarity and time proximity.
        
        Args:
            alerts: List of alerts to group
            
        Returns:
            List of alert groups
        """
        groups: Dict[str, List[AlertProtocol]] = defaultdict(list)
        
        # Sort alerts by timestamp
        sorted_alerts = sorted(alerts, key=lambda a: a.fired_at)
        
        for alert in sorted_alerts:
            group_key = self.group_key(alert)
            
            # Check if alert fits in existing group
            placed = False
            for existing_group_key, group_alerts in groups.items():
                if existing_group_key == group_key:
                    # Check time window
                    latest_alert = max(group_alerts, key=lambda a: a.fired_at)
                    time_diff = alert.fired_at - latest_alert.fired_at
                    
                    if time_diff <= self.time_window:
                        # Check similarity
                        if self.calculate_similarity(alert, latest_alert) >= self.similarity_threshold:
                            groups[existing_group_key].append(alert)
                            placed = True
                            break
            
            if not placed:
                # Create new group
                groups[group_key].append(alert)
        
        # Convert to AlertGroup objects
        alert_groups = []
        for group_key, group_alerts in groups.items():
            group = AlertGroup(
                group_key=group_key,
                first_seen=min(a.fired_at for a in group_alerts),
                last_seen=max(a.fired_at for a in group_alerts),
                alert_count=len(group_alerts)
            )
            alert_groups.append(group)
        
        return alert_groups
    
    def calculate_similarity(self, 
                           alert1: AlertProtocol, 
                           alert2: AlertProtocol) -> float:
        """Calculate similarity score between two alerts using Jaccard index.
        
        Args:
            alert1: First alert
            alert2: Second alert
            
        Returns:
            Similarity score between 0 and 1
        """
        # Extract label sets
        labels1 = set(alert1.labels.items())
        labels2 = set(alert2.labels.items())
        
        # Calculate Jaccard similarity
        intersection = labels1.intersection(labels2)
        union = labels1.union(labels2)
        
        if not union:
            return 0.0
        
        jaccard_score = len(intersection) / len(union)
        
        # Boost score if alert names match
        if alert1.alert_name == alert2.alert_name:
            jaccard_score = min(1.0, jaccard_score + 0.3)
        
        # Consider severity
        if alert1.severity == alert2.severity:
            jaccard_score = min(1.0, jaccard_score + 0.1)
        
        return jaccard_score
    
    def cluster(self, alerts: List[AlertProtocol]) -> Dict[str, List[AlertProtocol]]:
        """Cluster alerts into groups (alternative grouping method).
        
        Args:
            alerts: List of alerts to cluster
            
        Returns:
            Dictionary mapping group keys to alert lists
        """
        clusters: Dict[str, List[AlertProtocol]] = defaultdict(list)
        
        for alert in alerts:
            key = self.group_key(alert)
            clusters[key].append(alert)
        
        return clusters