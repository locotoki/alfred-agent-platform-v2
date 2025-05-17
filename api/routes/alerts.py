"""Alert API routes including grouping functionality."""

from datetime import timedelta
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query, Header
from pydantic import BaseModel

from alfred.alerts.grouping import AlertGroupingService
from alfred.alerts.feature_flags import AlertFeatureFlags

router = APIRouter(prefix="/api/v1/alerts", tags=["alerts"])


class GroupedAlertsRequest(BaseModel):
    """Request for grouped alerts."""
    strategy: str = "jaccard"
    time_window: int = 900  # 15 minutes in seconds


class GroupedAlertResponse(BaseModel):
    """Response for a grouped alert."""
    id: str
    key: str
    count: int
    first_seen: str
    last_seen: str
    severity: str


class GroupedAlertsResponse(BaseModel):
    """Response containing grouped alerts."""
    groups: List[GroupedAlertResponse]


@router.post("/grouped", response_model=GroupedAlertsResponse)
async def get_grouped_alerts(
    request: GroupedAlertsRequest,
    feature_flag: Optional[str] = Header(None, alias="X-Feature-Flag")
):
    """Get grouped alerts based on similarity and time window.
    
    Args:
        request: Grouping parameters
        feature_flag: Feature flag header
        
    Returns:
        Grouped alerts response
    """
    # Check feature flag
    if not AlertFeatureFlags.is_enabled(AlertFeatureFlags.ALERT_GROUPING_ENABLED):
        if feature_flag != "on":
            raise HTTPException(
                status_code=403, 
                detail="Alert grouping feature is disabled"
            )
    
    # Get alerts from database (mock for now)
    alerts = []  # TODO: Fetch from database
    
    # Initialize grouping service
    time_window = timedelta(seconds=request.time_window)
    grouping_service = AlertGroupingService(time_window=time_window)
    
    # Group alerts
    groups = grouping_service.group_alerts(alerts)
    
    # Convert to response format
    response_groups = []
    for group in groups:
        response_groups.append(GroupedAlertResponse(
            id=str(group.id),
            key=group.group_key,
            count=group.alert_count,
            first_seen=group.first_seen.isoformat(),
            last_seen=group.last_seen.isoformat(),
            severity="high"  # TODO: Get from actual alerts
        ))
    
    return GroupedAlertsResponse(groups=response_groups)