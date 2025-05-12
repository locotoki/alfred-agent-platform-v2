#!/usr/bin/env python3
"""
Enhanced document processor for Atlas RAG
Indexes documents with better chunking, metadata, and progress tracking
"""

import os
import sys
import json
import glob
import requests
import time
import argparse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict, Any, Optional
import re

def setup_argparse() -> argparse.ArgumentParser:
    """Set up command line arguments"""
    parser = argparse.ArgumentParser(
        description="Process and index documents for Atlas RAG"
    )
    parser.add_argument(
        "path", 
        help="Path to directory containing documents to index"
    )
    parser.add_argument(
        "-u", "--url", 
        default=os.environ.get("RAG_URL", "http://localhost:8501"),
        help="RAG service URL (default: $RAG_URL or http://localhost:8501)"
    )
    parser.add_argument(
        "-c", "--chunk-size", 
        type=int, 
        default=int(os.environ.get("CHUNK_SIZE", "1000")),
        help="Chunk size in characters (default: $CHUNK_SIZE or 1000)"
    )
    parser.add_argument(
        "-o", "--overlap", 
        type=int, 
        default=int(os.environ.get("OVERLAP", "200")),
        help="Overlap between chunks in characters (default: $OVERLAP or 200)"
    )
    parser.add_argument(
        "-m", "--max-files", 
        type=int, 
        default=int(os.environ.get("MAX_FILES", "500")),
        help="Maximum number of files to process (default: $MAX_FILES or 500)"
    )
    parser.add_argument(
        "-e", "--extensions", 
        default=os.environ.get("EXTENSIONS", "md,py,js,ts,html,css,json,yaml,yml,txt"),
        help="Comma-separated list of file extensions to process (default: md,py,js,ts,html,css,json,yaml,yml,txt)"
    )
    parser.add_argument(
        "-w", "--workers", 
        type=int, 
        default=int(os.environ.get("WORKERS", "4")),
        help="Number of worker threads for processing (default: $WORKERS or 4)"
    )
    parser.add_argument(
        "-b", "--batch-size", 
        type=int, 
        default=int(os.environ.get("BATCH_SIZE", "25")),
        help="Number of chunks to send in each batch (default: $BATCH_SIZE or 25)"
    )
    parser.add_argument(
        "--dry-run", 
        action="store_true",
        help="Process files but don't send to RAG service"
    )
    parser.add_argument(
        "-v", "--verbose", 
        action="store_true",
        help="Enable verbose output"
    )
    return parser

def chunk_text(text: str, chunk_size: int, overlap: int) -> List[str]:
    """Split text into overlapping chunks with smarter boundaries"""
    chunks = []
    start = 0
    
    while start < len(text):
        end = min(start + chunk_size, len(text))
        
        # Try to break at paragraph or sentence
        if end < len(text):
            # Look for paragraph break
            paragraph_break = text.rfind('\n\n', start, end)
            if paragraph_break != -1 and paragraph_break > start + chunk_size / 2:
                end = paragraph_break + 2
            else:
                # Look for line break
                line_break = text.rfind('\n', start, end)
                if line_break != -1 and line_break > start + chunk_size / 2:
                    end = line_break + 1
                else:
                    # Look for sentence break
                    sentence_break = text.rfind('. ', start, end)
                    if sentence_break != -1 and sentence_break > start + chunk_size / 2:
                        end = sentence_break + 2
                    else:
                        # Look for space as last resort
                        space = text.rfind(' ', start + chunk_size // 2, end)
                        if space != -1:
                            end = space + 1
        
        chunks.append(text[start:end])
        start = end - overlap
    
    return chunks

def detect_code_blocks(text: str) -> bool:
    """Check if text contains code blocks"""
    # Check for markdown code blocks or indented code
    code_patterns = [
        r'```[a-z]*\n[\s\S]*?\n```',  # Markdown code blocks
        r'(?:^[ \t].*\n){4,}',         # Indented code (4+ lines)
        r'(?:^import |^from .+ import)',  # Python imports
        r'(?:^def |^class )',            # Python functions/classes
        r'function [a-zA-Z0-9_]+\(',     # JavaScript functions
        r'(?:^const |^let |^var )',      # JavaScript variables
    ]
    for pattern in code_patterns:
        if re.search(pattern, text, re.MULTILINE):
            return True
    return False

def get_file_metadata(file_path: str, rel_path: str) -> Dict[str, Any]:
    """Extract metadata from file"""
    stat = os.stat(file_path)
    is_code = rel_path.endswith(('.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.c', '.cpp', '.go', '.rs'))
    
    # Check for common metadata headers in markdown
    metadata = {}
    try:
        with open(file_path, 'r') as f:
            content = f.read(4000)  # Read just the beginning to check for metadata
            
            # Check for YAML frontmatter
            yaml_match = re.search(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
            if yaml_match:
                yaml_text = yaml_match.group(1)
                # Extract simple key-value pairs without parsing YAML
                for line in yaml_text.split('\n'):
                    if ':' in line:
                        key, value = line.split(':', 1)
                        metadata[key.strip().lower()] = value.strip()
            
            # Check for title
            if 'title' not in metadata:
                title_match = re.search(r'^#\s+(.*?)$', content, re.MULTILINE)
                if title_match:
                    metadata['title'] = title_match.group(1)
            
            # Check for code files
            if is_code or detect_code_blocks(content):
                metadata['content_type'] = 'code'
            else:
                metadata['content_type'] = 'text'
    except Exception as e:
        print(f"Error extracting metadata from {file_path}: {e}")
    
    return {
        'filename': os.path.basename(file_path),
        'path': rel_path,
        'size': stat.st_size,
        'last_modified': stat.st_mtime,
        **metadata
    }

def process_file(file_path: str, base_path: str, chunk_size: int, overlap: int, verbose: bool) -> List[Dict[str, Any]]:
    """Process a file and return chunks with metadata"""
    try:
        rel_path = os.path.relpath(file_path, base_path)
        
        if verbose:
            print(f"Processing {rel_path}...")
        
        with open(file_path, 'r', errors='replace') as f:
            content = f.read()
        
        # Skip empty files
        if not content.strip():
            if verbose:
                print(f"Skipping empty file: {rel_path}")
            return []
        
        # Get file metadata
        metadata = get_file_metadata(file_path, rel_path)
        
        # Chunk the content
        chunks = chunk_text(content, chunk_size, overlap)
        
        # Add metadata to each chunk
        result = []
        for i, chunk in enumerate(chunks):
            chunk_metadata = {
                **metadata,
                "chunk_index": i,
                "total_chunks": len(chunks)
            }
            
            # Add chunk metadata as prefix
            title = metadata.get('title', os.path.basename(rel_path))
            prefix = f"SOURCE: {rel_path} ({i+1}/{len(chunks)})\n"
            prefix += f"TITLE: {title}\n\n"
            
            result.append({
                "text": prefix + chunk,
                "metadata": chunk_metadata
            })
        
        if verbose:
            print(f"Created {len(chunks)} chunks from {rel_path}")
        
        return result
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
        return []

def send_batch(batch: List[Dict[str, Any]], rag_url: str, dry_run: bool, verbose: bool) -> Optional[str]:
    """Send a batch of chunks to the RAG service"""
    if dry_run:
        if verbose:
            print(f"[DRY RUN] Would send batch of {len(batch)} chunks")
        return "dry-run-job-id"
    
    try:
        # Extract just the text from each chunk for the API
        texts = [chunk["text"] for chunk in batch]
        
        response = requests.post(
            f"{rag_url}/v1/embed_batch",
            json=texts,
            timeout=60
        )
        
        if response.status_code == 200:
            return response.json().get('job_id')
        else:
            print(f"Error submitting batch: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"Error sending batch to RAG service: {str(e)}")
        return None

def main():
    """Main entry point"""
    parser = setup_argparse()
    args = parser.parse_args()
    
    # Check if path exists
    if not os.path.isdir(args.path):
        print(f"Error: Directory {args.path} does not exist")
        sys.exit(1)
    
    # Get absolute path
    base_path = os.path.abspath(args.path)
    print(f"Indexing files in {base_path} with extensions: {args.extensions}")
    print(f"RAG URL: {args.url}")
    print(f"Chunk size: {args.chunk_size}, Overlap: {args.overlap}")
    print(f"Maximum files: {args.max_files}, Workers: {args.workers}")
    
    if args.dry_run:
        print("DRY RUN: Files will be processed but not sent to RAG service")
    
    # Find files matching extensions
    extensions = args.extensions.split(',')
    all_files = []
    for ext in extensions:
        pattern = os.path.join(base_path, f"**/*.{ext}")
        found = glob.glob(pattern, recursive=True)
        all_files.extend(found)
    
    # Limit number of files
    all_files = all_files[:args.max_files]
    print(f"Found {len(all_files)} files to process")
    
    # Process files in parallel
    start_time = time.time()
    all_chunks = []
    
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_file = {
            executor.submit(
                process_file, file_path, base_path, args.chunk_size, args.overlap, args.verbose
            ): file_path 
            for file_path in all_files
        }
        
        for i, future in enumerate(future_to_file):
            try:
                file_chunks = future.result()
                all_chunks.extend(file_chunks)
                if i % 10 == 0 or i == len(all_files) - 1:
                    print(f"Processed {i+1}/{len(all_files)} files, {len(all_chunks)} chunks so far...")
            except Exception as e:
                print(f"Error processing file: {str(e)}")
    
    print(f"Total chunks: {len(all_chunks)}")
    
    # Send chunks to RAG service in batches
    batch_size = args.batch_size
    jobs = []
    
    for i in range(0, len(all_chunks), batch_size):
        batch = all_chunks[i:i+batch_size]
        job_id = send_batch(batch, args.url, args.dry_run, args.verbose)
        
        if job_id:
            jobs.append(job_id)
            print(f"Submitted batch {i//batch_size + 1}/{(len(all_chunks) + batch_size - 1)//batch_size} - Job ID: {job_id}")
        else:
            print(f"Failed to submit batch {i//batch_size + 1}")
    
    end_time = time.time()
    duration = end_time - start_time
    
    print(f"\nIndexing complete!")
    print(f"Processed {len(all_files)} files into {len(all_chunks)} chunks")
    print(f"Submitted {len(jobs)} batches to RAG service")
    print(f"Total processing time: {duration:.2f} seconds")

if __name__ == "__main__":
    main()