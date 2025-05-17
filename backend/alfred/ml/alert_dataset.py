"""Alert dataset loader for ML training."""
from datetime import datetime, timedelta
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import Session
from ..config.settings import settings

def load_alert_dataset(days=30):
    """Load alert data from the last N days.
    
    Args:
        days: Number of days of historical data to load
        
    Returns:
        List of (text, label) tuples for training
    """
    engine = create_engine(settings.ALERT_DB_URI)
    
    # Calculate date range
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days)
    
    query = text("""
        SELECT message, severity
        FROM alerts
        WHERE created_at >= :start_date
        AND created_at <= :end_date
        AND message IS NOT NULL
        ORDER BY created_at DESC
    """)
    
    results = []
    with Session(engine) as session:
        rows = session.execute(
            query,
            {"start_date": start_date, "end_date": end_date}
        ).fetchall()
        
        for row in rows:
            # Strip PII from messages
            message = _strip_pii(row.message)
            # Map severity to label
            label = _severity_to_label(row.severity)
            results.append((message, label))
    
    return results

def _strip_pii(message: str) -> str:
    """Remove potential PII from alert messages."""
    import re
    # Remove email addresses
    message = re.sub(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', '[EMAIL]', message)
    # Remove IP addresses
    message = re.sub(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b', '[IP]', message)
    # Remove phone numbers (basic pattern)
    message = re.sub(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', '[PHONE]', message)
    return message

def _severity_to_label(severity: str) -> str:
    """Map alert severity to training label."""
    severity_map = {
        "critical": "critical",
        "error": "critical",
        "warning": "warning",
        "info": "noise",
        "debug": "noise"
    }
    return severity_map.get(severity.lower(), "noise")