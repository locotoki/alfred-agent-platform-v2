"""Protocol interfaces for alfred.rag module.

This module defines the abstract interfaces used throughout the alfred.rag subsystem for
retrieval-augmented generation functionality.
"""

from abc import abstractmethod
from typing import Any, Dict, List, Optional, Protocol, Tuple


class VectorStore(Protocol):
    """Protocol for vector database operations"""

    @abstractmethod
    async def add_documents(
        self, documents: List[Dict[str, Any]], collection_name: str
    ) -> List[str]:
        """Add documents to the vector store.

        Args:
            documents: List of documents with content and metadata.
            collection_name: Name of the collection to add to.

        Returns:
            List of document IDs.
        """
        ...

    @abstractmethod
    async def search(
        self, query: str, collection_name: str, k: int = 10
    ) -> List[Tuple[Dict[str, Any], float]]:
        """Search for similar documents.

        Args:
            query: Search query.
            collection_name: Collection to search in.
            k: Number of results to return.

        Returns:
            List of (document, similarity_score) tuples.
        """
        ...

    @abstractmethod
    async def delete_documents(
        self, document_ids: List[str], collection_name: str
    ) -> bool:
        """Delete documents from the vector store.

        Args:
            document_ids: IDs of documents to delete.
            collection_name: Collection to delete from.

        Returns:
            True if deletion was successful.
        """
        ...

    @abstractmethod
    async def create_collection(
        self, collection_name: str, config: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Create a new collection.

        Args:
            collection_name: Name of the collection.
            config: Optional configuration for the collection.

        Returns:
            True if creation was successful.
        """
        ...


class Embedder(Protocol):
    """Protocol for text embedding generation"""

    @abstractmethod
    async def embed_text(self, text: str) -> List[float]:
        """Generate embedding for a single text.

        Args:
            text: Text to embed.

        Returns:
            Embedding vector.
        """
        ...

    @abstractmethod
    async def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for multiple texts.

        Args:
            texts: List of texts to embed.

        Returns:
            List of embedding vectors.
        """
        ...

    @abstractmethod
    def get_dimension(self) -> int:
        """Get the dimension of embeddings.

        Returns:
            Embedding dimension.
        """
        ...


class DocumentProcessor(Protocol):
    """Protocol for document processing and chunking"""

    @abstractmethod
    def process_document(
        self, content: str, metadata: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Process a document into chunks.

        Args:
            content: Document content.
            metadata: Document metadata.

        Returns:
            List of processed chunks with metadata.
        """
        ...

    @abstractmethod
    def clean_text(self, text: str) -> str:
        """Clean and normalize text.

        Args:
            text: Raw text.

        Returns:
            Cleaned text.
        """
        ...


class RAGEngine(Protocol):
    """Protocol for the main RAG engine"""

    @abstractmethod
    async def retrieve_and_generate(self, query: str, context_limit: int = 5) -> str:
        """Retrieve relevant context and generate a response.

        Args:
            query: User query.
            context_limit: Maximum number of context documents.

        Returns:
            Generated response.
        """
        ...

    @abstractmethod
    async def index_documents(self, documents: List[Dict[str, Any]]) -> bool:
        """Index new documents into the RAG system.

        Args:
            documents: Documents to index.

        Returns:
            True if indexing was successful.
        """
        ...

    @abstractmethod
    def get_config(self) -> Dict[str, Any]:
        """Get current RAG configuration.

        Returns:
            Configuration dictionary.
        """
        ...
