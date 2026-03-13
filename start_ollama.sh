#!/bin/bash

echo "=========================================="
echo "Starting Ollama Server"
echo "=========================================="
echo ""

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "Error: Ollama is not installed"
    echo "Install from: https://ollama.ai"
    exit 1
fi

# Check if already running
if lsof -ti:11434 > /dev/null 2>&1; then
    echo "Ollama is already running on port 11434"
    exit 0
fi

# Start Ollama
echo "Starting Ollama..."
ollama serve

# This will keep running until you press Ctrl+C
