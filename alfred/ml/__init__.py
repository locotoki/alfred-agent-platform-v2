"""Alfred ML module for noise reduction, threshold optimization, and embeddings."""

from typing import List

from .hf_embedder import HFEmbedder
from .noise_ranker import NoiseRankingModel
from .thresholds import ThresholdConfig, ThresholdService

__all__: List[str] = [
    "HFEmbedder",
    "NoiseRankingModel",
    "ThresholdConfig",
    "ThresholdService",
]
