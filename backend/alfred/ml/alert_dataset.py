"""Alert dataset loader for ML training."""

def load_alert_dataset(days=30):
    """Load alert data from the last N days.
    
    Args:
        days: Number of days of historical data to load
        
    Returns:
        List of (text, label) tuples for training
    """
    # TODO: Implement actual data loading from database
    # Stub data for now
    return [
        ("API timeout error in service X", "noise"),
        ("Database connection failed", "critical"),
        ("Memory usage exceeded 90%", "warning"),
        # Add more samples as needed
    ]