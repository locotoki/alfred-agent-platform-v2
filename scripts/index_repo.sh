#!/usr/bin/env bash
set -e

# Default values
RAG_URL=${RAG_URL:-"http://localhost:8501"}
CHUNK_SIZE=${CHUNK_SIZE:-1000}
OVERLAP=${OVERLAP:-200}
MAX_FILES=${MAX_FILES:-500}

# Print usage information
function usage() {
  echo "Usage: $0 [options] <path>"
  echo "Index files in a repository to the RAG service"
  echo
  echo "Options:"
  echo "  -h, --help        Show this help message"
  echo "  -u, --url URL     RAG service URL (default: $RAG_URL)"
  echo "  -c, --chunk SIZE  Chunk size in characters (default: $CHUNK_SIZE)"
  echo "  -o, --overlap N   Overlap between chunks (default: $OVERLAP)"
  echo "  -m, --max N       Maximum number of files to process (default: $MAX_FILES)"
  echo "  -e, --ext EXTS    File extensions to process (default: md,py,js,ts,html,css,json,yaml,yml)"
  echo
  echo "Example:"
  echo "  $0 ./docs"
  echo "  $0 --chunk 500 --ext md,txt ./documentation"
  exit 1
}

# Parse command line arguments
EXTENSIONS="md,py,js,ts,html,css,json,yaml,yml"
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      usage
      ;;
    -u|--url)
      RAG_URL="$2"
      shift
      shift
      ;;
    -c|--chunk)
      CHUNK_SIZE="$2"
      shift
      shift
      ;;
    -o|--overlap)
      OVERLAP="$2"
      shift
      shift
      ;;
    -m|--max)
      MAX_FILES="$2"
      shift
      shift
      ;;
    -e|--ext)
      EXTENSIONS="$2"
      shift
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done
set -- "${POSITIONAL[@]}"

# Check for required arguments
if [ $# -lt 1 ]; then
  echo "Error: Path argument is required"
  usage
fi

PATH_TO_INDEX="$1"

# Check if path exists
if [ ! -d "$PATH_TO_INDEX" ]; then
  echo "Error: Directory $PATH_TO_INDEX does not exist"
  exit 1
fi

# Convert extensions to find pattern
FIND_PATTERN=$(echo $EXTENSIONS | sed 's/,/\\|/g')

echo "Indexing files in $PATH_TO_INDEX with extensions: $EXTENSIONS"
echo "RAG URL: $RAG_URL"
echo "Chunk size: $CHUNK_SIZE, Overlap: $OVERLAP"
echo "Maximum files: $MAX_FILES"

# Get the base path to use for calculating relative paths
BASE_PATH=$(cd "$PATH_TO_INDEX" && pwd)

# Use Python to process and index files
python3 - <<EOF
import os
import sys
import json
import glob
import requests
from pathlib import Path

# Configuration
rag_url = "${RAG_URL}"
base_path = "${BASE_PATH}"
chunk_size = ${CHUNK_SIZE}
overlap = ${OVERLAP}
max_files = ${MAX_FILES}
extensions = "${EXTENSIONS}".split(",")

def chunk_text(text, chunk_size, overlap):
    """Split text into overlapping chunks"""
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
        
        chunks.append(text[start:end])
        start = end - overlap
    
    return chunks

def process_file(file_path):
    """Process a file and return chunks with metadata"""
    try:
        rel_path = os.path.relpath(file_path, base_path)
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Skip empty files
        if not content.strip():
            return []
        
        chunks = chunk_text(content, chunk_size, overlap)
        
        # Add metadata to each chunk
        result = []
        for i, chunk in enumerate(chunks):
            metadata = {
                "source": rel_path,
                "chunk_index": i,
                "total_chunks": len(chunks)
            }
            # Add chunk metadata as prefix
            prefix = f"SOURCE: {rel_path} (Chunk {i+1}/{len(chunks)})\n\n"
            result.append(prefix + chunk)
        
        return result
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")
        return []

# Find files matching extensions
all_files = []
for ext in extensions:
    pattern = os.path.join(base_path, f"**/*.{ext}")
    all_files.extend(glob.glob(pattern, recursive=True))

# Limit number of files
all_files = all_files[:max_files]
print(f"Found {len(all_files)} files to process")

# Process files and collect chunks
all_chunks = []
for file_path in all_files:
    chunks = process_file(file_path)
    all_chunks.extend(chunks)
    print(f"Processed {file_path} - {len(chunks)} chunks")

print(f"Total chunks: {len(all_chunks)}")

# Send chunks to RAG service in batches
batch_size = 25
for i in range(0, len(all_chunks), batch_size):
    batch = all_chunks[i:i+batch_size]
    try:
        response = requests.post(f"{rag_url}/v1/embed_batch", json=batch)
        if response.status_code == 200:
            job_id = response.json().get('job_id')
            print(f"Submitted batch {i//batch_size + 1}/{(len(all_chunks) + batch_size - 1)//batch_size} - Job ID: {job_id}")
        else:
            print(f"Error submitting batch: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error sending batch to RAG service: {str(e)}")

print("Indexing complete!")
EOF