"""
Enhanced NicheScout implementation with RAG integration.
This demonstrates using the RAG Gateway while maintaining compatibility with direct Qdrant.
"""

import os
import json
import time
import uuid
import structlog
from typing import Dict, List, Any, Tuple
from app.clients import rag_client, MIGRATION_MODE
from app.niche_scout import NicheScout

logger = structlog.get_logger(__name__)

class EnhancedNicheScout(NicheScout):
    """
    Enhanced NicheScout with platform service integration.
    Extends the base NicheScout class with RAG capabilities.
    """
    
    async def get_related_niches(self, query: str, category: str = None) -> List[Dict[str, Any]]:
        """
        Get related niches using RAG Gateway if available.
        Falls back to direct Qdrant if RAG Gateway is not available.
        
        Args:
            query: Search query
            category: Optional category filter
            
        Returns:
            List of related niches with relevance scores
        """
        # First try to use RAG Gateway if enabled
        if MIGRATION_MODE == "hybrid" or MIGRATION_MODE == "platform":
            try:
                # Prepare filter if category is provided
                filter_dict = {"category": category} if category else None
                
                # Get context from RAG Gateway
                rag_results = await rag_client.get_context(
                    query=query,
                    top_k=10,
                    context_type="youtube",
                    filter_dict=filter_dict
                )
                
                if rag_results:
                    # Transform RAG results to expected format
                    related_niches = []
                    for item in rag_results:
                        # Extract niche data from text and metadata
                        text = item.get("text", "")
                        metadata = item.get("metadata", {})
                        score = metadata.get("score", 0)
                        
                        # Create a niche object
                        niche = {
                            "phrase": text.split("\n")[0] if "\n" in text else text,
                            "score": float(score),
                            "opportunity": float(score) * 0.8,  # Simplified calculation
                            "category": metadata.get("category", category),
                            "source": metadata.get("source", "rag")
                        }
                        
                        related_niches.append(niche)
                    
                    logger.info(f"Retrieved {len(related_niches)} related niches from RAG Gateway")
                    if related_niches:
                        return related_niches
            except Exception as e:
                logger.error(f"Error getting related niches from RAG Gateway: {str(e)}")
                if MIGRATION_MODE == "platform":
                    # In platform-only mode, this is a critical error
                    raise
        
        # Fall back to original implementation
        logger.info("Falling back to original implementation for related niches")
        return await super().get_related_niches(query, category)
    
    async def store_niche_data(self, niches: List[Dict[str, Any]]) -> bool:
        """
        Store niche data for future retrieval.
        Stores in both RAG Gateway and original storage.
        
        Args:
            niches: List of niche data to store
            
        Returns:
            True if successful, False otherwise
        """
        success = True
        
        # Store in RAG Gateway if enabled
        if MIGRATION_MODE == "hybrid" or MIGRATION_MODE == "platform":
            try:
                # Transform niches to RAG documents
                documents = []
                for niche in niches:
                    # Create a text representation of the niche
                    text = f"{niche.get('phrase', '')}\n\n"
                    text += f"Opportunity Score: {niche.get('opportunity', 0)}\n"
                    text += f"Category: {niche.get('category', 'general')}\n"
                    
                    # Create a document object
                    document = {
                        "text": text,
                        "metadata": {
                            "source": f"niche-scout-{time.strftime('%Y-%m-%d')}",
                            "category": niche.get("category", "general"),
                            "opportunity": niche.get("opportunity", 0),
                            "type": "niche"
                        }
                    }
                    
                    documents.append(document)
                
                # Store in RAG Gateway
                if documents:
                    rag_success = await rag_client.store_documents(documents, "social-intel-knowledge")
                    if rag_success:
                        logger.info(f"Stored {len(documents)} niches in RAG Gateway")
                    else:
                        logger.warning("Failed to store niches in RAG Gateway")
                        success = False
            except Exception as e:
                logger.error(f"Error storing niches in RAG Gateway: {str(e)}")
                success = False
                if MIGRATION_MODE == "platform":
                    # In platform-only mode, this is a critical error
                    raise
        
        # Always store in original storage to maintain compatibility
        try:
            original_success = await super().store_niche_data(niches)
            if not original_success:
                logger.warning("Failed to store niches in original storage")
                success = False
        except Exception as e:
            logger.error(f"Error storing niches in original storage: {str(e)}")
            success = False
        
        return success
    
    async def run(self, query: str, category: str = None, subcategory: str = None) -> Tuple[Dict[str, Any], str, str]:
        """
        Run the niche scout workflow with enhanced functionality.
        
        Args:
            query: Search query
            category: Optional category filter
            subcategory: Optional subcategory filter
            
        Returns:
            Tuple of (result data, JSON file path, report file path)
        """
        # Start with basic preparation steps from original implementation
        run_id = str(uuid.uuid4())
        start_time = time.time()
        
        logger.info(f"Starting enhanced niche scout run: {run_id}", 
                   query=query, category=category, mode=MIGRATION_MODE)
        
        # Get related niches using enhanced method
        related_niches = await self.get_related_niches(query, category)
        
        # Continue with original implementation for market analysis
        # This is a simplified version - in reality, we'd use more of the original implementation
        result = {
            "run_id": run_id,
            "query": query,
            "category": category,
            "subcategory": subcategory,
            "run_date": time.time(),
            "niches": related_niches,
            "duration_seconds": time.time() - start_time
        }
        
        # Generate output files as in original implementation
        json_file = f"/app/data/niche_scout/{run_id}.json"
        report_file = f"/app/data/niche_scout/{run_id}.md"
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(json_file), exist_ok=True)
        
        # Write JSON result
        with open(json_file, 'w') as f:
            json.dump(result, f, indent=2)
        
        # Generate and write report
        report_content = f"# Niche Scout Report\n\n"
        report_content += f"Query: {query}\n"
        report_content += f"Category: {category or 'Any'}\n\n"
        report_content += f"## Top Niches\n\n"
        
        for i, niche in enumerate(sorted(related_niches, key=lambda x: x.get("opportunity", 0), reverse=True)[:10]):
            report_content += f"{i+1}. {niche.get('phrase')} - Opportunity: {niche.get('opportunity'):.2f}\n"
        
        with open(report_file, 'w') as f:
            f.write(report_content)
        
        # Store niche data for future use
        await self.store_niche_data(related_niches)
        
        return result, json_file, report_file