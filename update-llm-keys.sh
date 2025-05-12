#!/bin/bash
# Script to update LLM API keys from main .env file to .env.llm

# Check if files exist
if [ ! -f .env ] || [ ! -f .env.llm ]; then
    echo "Error: .env or .env.llm file not found"
    exit 1
fi

# Extract OpenAI API key from main .env file
OPENAI_KEY=$(grep "OPENAI_API_KEY" .env | cut -d'=' -f2)

if [ -z "$OPENAI_KEY" ]; then
    echo "Warning: No OpenAI API key found in main .env file"
else
    echo "Found OpenAI API key in main .env file"
    
    # Update the .env.llm file
    sed -i "s/your_openai_api_key_here/$OPENAI_KEY/g" .env.llm
    echo "Updated ALFRED_OPENAI_API_KEY in .env.llm"
fi

echo "Please manually add your Anthropic API key if needed"
echo "Done!"