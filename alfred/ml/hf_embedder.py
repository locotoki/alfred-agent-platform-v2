"""HuggingFace transformers integration for alert embeddings"""

import logging
import os
from typing import List, Union

import numpy as np
from sentence_transformers import SentenceTransformer

from alfred.core.protocols import Service

logger = logging.getLogger(__name__)


class HFEmbedder(Service):
    """HuggingFace transformer-based embedder for alert messages.

    Uses MiniLM model for efficient semantic embeddings with balanced performance and
    resource usage.
    """

    DEFAULT_MODEL = "all-MiniLM-L6-v2"
    CACHE_DIR = os.path.expanduser("~/.cache/huggingface")

    def __init__(
        self,
        model_name: str = DEFAULT_MODEL,
        device: str = "cpu",
        batch_size: int = 32,
    ):
        """Initialize the HuggingFace embedder.

        Args:
            model_name: HuggingFace model name (default: all-MiniLM-L6-v2)
            device: Device to run model on (cpu/cuda)
            batch_size: Batch size for encoding.
        """
        self.model_name = model_name
        self.device = device
        self.batch_size = batch_size
        self._model = None

    @property
    def model(self) -> SentenceTransformer:
        """Lazy load the model on first use"""
        if self._model is None:
            logger.info(f"Loading HuggingFace model: {self.model_name}")
            self._model = SentenceTransformer(
                self.model_name, device=self.device, cache_folder=self.CACHE_DIR
            )
            logger.info(f"Model loaded: {self.model_name} on {self.device}")
        return self._model

    def embed(self, texts: Union[str, List[str]]) -> np.ndarray:
        """Generate embeddings for input text(s).

        Args:
            texts: Single text or list of texts to embed

        Returns:
            Numpy array of embeddings (1D for single text, 2D for list).
        """
        if isinstance(texts, str):
            texts = [texts]
            single_input = True
        else:
            single_input = False

        # Clean texts
        texts = [self._clean_text(text) for text in texts]

        # Generate embeddings
        embeddings = self.model.encode(
            texts,
            batch_size=self.batch_size,
            show_progress_bar=False,
            convert_to_numpy=True,
        )

        # Return single embedding if single input
        if single_input:
            return embeddings[0]
        return embeddings

    def cosine_similarity(self, embeddings1: np.ndarray, embeddings2: np.ndarray) -> float:
        """Calculate cosine similarity between embeddings.

        Args:
            embeddings1: First embedding vector
            embeddings2: Second embedding vector

        Returns:
            Cosine similarity score (0-1).
        """
        # Normalize vectors
        norm1 = np.linalg.norm(embeddings1)
        norm2 = np.linalg.norm(embeddings2)

        if norm1 == 0 or norm2 == 0:
            return 0.0

        # Calculate cosine similarity
        dot_product = np.dot(embeddings1, embeddings2)
        similarity = dot_product / (norm1 * norm2)

        # Clip to valid range
        return float(np.clip(similarity, 0.0, 1.0))

    def batch_similarity(
        self, query_embedding: np.ndarray, candidate_embeddings: np.ndarray
    ) -> np.ndarray:
        """Calculate similarities between query and multiple candidates.

        Args:
            query_embedding: Query embedding vector
            candidate_embeddings: Matrix of candidate embeddings

        Returns:
            Array of similarity scores.
        """
        # Normalize query
        query_norm = query_embedding / np.linalg.norm(query_embedding)

        # Normalize candidates
        candidate_norms = np.linalg.norm(candidate_embeddings, axis=1, keepdims=True)
        normalized_candidates = candidate_embeddings / (candidate_norms + 1e-8)

        # Calculate similarities
        similarities = np.dot(normalized_candidates, query_norm)

        return np.clip(similarities, 0.0, 1.0)

    def _clean_text(self, text: str) -> str:
        """Clean text for embedding.

        Args:
            text: Input text

        Returns:
            Cleaned text.
        """
        # Basic cleaning
        text = text.strip()

        # Remove excessive whitespace
        text = " ".join(text.split())

        # Truncate very long texts
        if len(text) > 512:
            text = text[:512] + "..."

        return text

    def warmup(self) -> None:
        """Warm up the model by loading it into memory"""
        _ = self.model  # Trigger lazy loading
        logger.info(f"Model warmed up: {self.model_name}")

    def get_model_info(self) -> dict:
        """Get information about the loaded model.

        Returns:
            Dictionary with model metadata.
        """
        return {
            "model_name": self.model_name,
            "device": self.device,
            "batch_size": self.batch_size,
            "embedding_dimension": self.model.get_sentence_embedding_dimension(),
            "max_seq_length": self.model.max_seq_length,
        }
