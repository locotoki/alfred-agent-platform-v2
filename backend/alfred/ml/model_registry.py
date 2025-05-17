"""Model registry for managing trained models."""

def should_promote(metrics):
    """Determine if model should be promoted based on metrics.
    
    Args:
        metrics: Dict with 'noise_cut' and 'fnr' values
        
    Returns:
        bool: True if model meets promotion criteria
    """
    # Promotion criteria
    NOISE_CUT_THRESHOLD = 0.45  # >= 45% noise reduction
    FNR_THRESHOLD = 0.02  # < 2% false negative rate
    
    return (metrics["noise_cut"] >= NOISE_CUT_THRESHOLD and 
            metrics["fnr"] < FNR_THRESHOLD)


def save_promoted_model(model_path, metrics):
    """Save promoted model to registry.
    
    Args:
        model_path: Path to the trained model
        metrics: Performance metrics dict
    """
    # TODO: Implement actual model registry integration
    print(f"Model promoted with metrics: {metrics}")
    print(f"Saving model from: {model_path}")